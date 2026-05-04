import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/crypto_utils.dart';

/// Service Hyperledger Fabric — MauriVote
///
/// Intègre le réseau blockchain privé Hyperledger Fabric pour :
///   • Enregistrement immuable de chaque vote chiffré
///   • Audit trail vérifiable par la CENI et observateurs
///   • Résistance à la falsification (consensus PBFT)
///
/// Architecture : Flutter → Fabric Gateway REST API → Peers Fabric
/// Référence : https://hyperledger-fabric.readthedocs.io/en/latest/
///             https://github.com/hyperledger/fabric-gateway
class BlockchainService {
  static const _channelName   = 'maurivote-channel';
  static const _chaincodeName = 'vote-chaincode';

  final Dio _dio;
  final String _gatewayUrl;

  BlockchainService({String? gatewayUrl})
      : _gatewayUrl = gatewayUrl ?? 'https://fabric-gateway.maurivote.mr',
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'X-Channel':    _channelName,
            'X-Chaincode':  _chaincodeName,
          },
        ));

  // ── ENREGISTRER UN VOTE SUR BLOCKCHAIN ───────────────────────────────────
  /// Soumet une transaction Fabric pour enregistrer le vote chiffré
  /// La transaction est validée par les peers CENI, observateurs et gouvernement
  Future<BlockchainReceipt> submitVoteTransaction({
    required String voterHash,
    required String electionId,
    required String voteChiffre,
    required String recuHash,
    required int    tour,
    String? electionGuardCiphertext,
  }) async {
    final payload = {
      'function':   'SubmitVote',
      'channel':    _channelName,
      'chaincode':  _chaincodeName,
      'args': [
        voterHash,
        electionId,
        voteChiffre,
        recuHash,
        tour.toString(),
        electionGuardCiphertext ?? '',
        DateTime.now().toUtc().toIso8601String(),
      ],
      'transient': {
        'signature': CryptoUtils.hmacSign(
          data: voterHash + electionId + recuHash,
          key:  voteChiffre.substring(0, 16),
        ),
      },
    };

    try {
      final response = await _dio.post(
        '$_gatewayUrl/transactions/submit',
        data: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        return BlockchainReceipt(
          txId:          data['txId'] ?? '',
          blockNumber:   data['blockNumber'] ?? 0,
          timestamp:     DateTime.parse(
              data['timestamp'] ?? DateTime.now().toIso8601String()),
          status:        BlockchainTxStatus.committed,
          endorsers:     List<String>.from(data['endorsers'] ?? []),
          channelId:     _channelName,
        );
      }
      throw BlockchainException('Transaction rejetée: ${response.statusCode}');
    } on DioException catch (e) {
      debugPrint('Fabric submit error: $e');
      // Mode dégradé : enregistrement local en attente
      return BlockchainReceipt(
        txId:        _generateLocalTxId(recuHash),
        blockNumber: -1,
        timestamp:   DateTime.now(),
        status:      BlockchainTxStatus.pending,
        endorsers:   [],
        channelId:   _channelName,
      );
    }
  }

  // ── VÉRIFIER UN VOTE SUR BLOCKCHAIN ──────────────────────────────────────
  /// Interroge le ledger Fabric pour vérifier qu'un vote existe
  Future<BlockchainVoteRecord?> queryVote(String recuHash) async {
    try {
      final response = await _dio.post(
        '$_gatewayUrl/transactions/evaluate',
        data: jsonEncode({
          'function':  'QueryVote',
          'channel':   _channelName,
          'chaincode': _chaincodeName,
          'args':      [recuHash],
        }),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return BlockchainVoteRecord.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Fabric query error: $e');
      return null;
    }
  }

  // ── RÉCUPÉRER LE TALLY BLOCKCHAIN ────────────────────────────────────────
  /// Récupère le décompte agrégé depuis le ledger (public — read-only)
  Future<List<BlockchainTallyEntry>> queryTally({
    required String electionId,
    int tour = 1,
  }) async {
    try {
      final response = await _dio.post(
        '$_gatewayUrl/transactions/evaluate',
        data: jsonEncode({
          'function':  'GetTally',
          'channel':   _channelName,
          'chaincode': _chaincodeName,
          'args':      [electionId, tour.toString()],
        }),
      );

      if (response.statusCode == 200) {
        final list = response.data as List;
        return list.map((e) => BlockchainTallyEntry.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Fabric tally error: $e');
      return [];
    }
  }

  // ── AUDIT TRAIL ───────────────────────────────────────────────────────────
  /// Récupère l'historique complet d'un vote (immuable sur Fabric)
  Future<List<BlockchainAuditEntry>> getAuditTrail(String voterHash) async {
    try {
      final response = await _dio.post(
        '$_gatewayUrl/transactions/evaluate',
        data: jsonEncode({
          'function':  'GetVoteHistory',
          'channel':   _channelName,
          'chaincode': _chaincodeName,
          'args':      [voterHash],
        }),
      );

      if (response.statusCode == 200) {
        final list = response.data as List;
        return list.map((e) => BlockchainAuditEntry.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Fabric audit error: $e');
      return [];
    }
  }

  // ── SANTÉ DU RÉSEAU FABRIC ───────────────────────────────────────────────
  Future<FabricNetworkStatus> getNetworkStatus() async {
    try {
      final response = await _dio.get('$_gatewayUrl/health');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return FabricNetworkStatus(
          isOnline:    true,
          peerCount:   data['peers'] ?? 0,
          blockHeight: data['blockHeight'] ?? 0,
          channelId:   _channelName,
        );
      }
      return FabricNetworkStatus.offline();
    } catch (_) {
      return FabricNetworkStatus.offline();
    }
  }

  String _generateLocalTxId(String recuHash) =>
      'LOCAL-${DateTime.now().millisecondsSinceEpoch}-${recuHash.substring(0, 8)}';
}

// ── Modèles Blockchain ────────────────────────────────────────────────────────
enum BlockchainTxStatus { pending, submitted, committed, failed }

class BlockchainReceipt {
  final String              txId;
  final int                 blockNumber;
  final DateTime            timestamp;
  final BlockchainTxStatus  status;
  final List<String>        endorsers;
  final String              channelId;

  const BlockchainReceipt({
    required this.txId,
    required this.blockNumber,
    required this.timestamp,
    required this.status,
    required this.endorsers,
    required this.channelId,
  });

  bool get isConfirmed => status == BlockchainTxStatus.committed;

  Map<String, dynamic> toJson() => {
    'tx_id':        txId,
    'block_number': blockNumber,
    'timestamp':    timestamp.toIso8601String(),
    'status':       status.name,
    'endorsers':    endorsers,
    'channel_id':   channelId,
  };
}

class BlockchainVoteRecord {
  final String   recuHash;
  final String   electionId;
  final String   voterHash;
  final DateTime submittedAt;
  final String   txId;
  final int      blockNumber;

  const BlockchainVoteRecord({
    required this.recuHash,
    required this.electionId,
    required this.voterHash,
    required this.submittedAt,
    required this.txId,
    required this.blockNumber,
  });

  factory BlockchainVoteRecord.fromJson(Map<String, dynamic> json) =>
      BlockchainVoteRecord(
        recuHash:    json['recu_hash'],
        electionId:  json['election_id'],
        voterHash:   json['voter_hash'],
        submittedAt: DateTime.parse(json['submitted_at']),
        txId:        json['tx_id'],
        blockNumber: json['block_number'] ?? 0,
      );
}

class BlockchainTallyEntry {
  final String candidateId;
  final int    nbVotes;
  final String lastTxId;

  const BlockchainTallyEntry({
    required this.candidateId,
    required this.nbVotes,
    required this.lastTxId,
  });

  factory BlockchainTallyEntry.fromJson(Map<String, dynamic> json) =>
      BlockchainTallyEntry(
        candidateId: json['candidate_id'],
        nbVotes:     json['nb_votes'] ?? 0,
        lastTxId:    json['last_tx_id'] ?? '',
      );
}

class BlockchainAuditEntry {
  final String   txId;
  final String   action;
  final DateTime timestamp;
  final String   peer;

  const BlockchainAuditEntry({
    required this.txId,
    required this.action,
    required this.timestamp,
    required this.peer,
  });

  factory BlockchainAuditEntry.fromJson(Map<String, dynamic> json) =>
      BlockchainAuditEntry(
        txId:      json['tx_id'],
        action:    json['action'],
        timestamp: DateTime.parse(json['timestamp']),
        peer:      json['peer'] ?? '',
      );
}

class FabricNetworkStatus {
  final bool   isOnline;
  final int    peerCount;
  final int    blockHeight;
  final String channelId;

  const FabricNetworkStatus({
    required this.isOnline,
    required this.peerCount,
    required this.blockHeight,
    required this.channelId,
  });

  factory FabricNetworkStatus.offline() => const FabricNetworkStatus(
    isOnline: false, peerCount: 0, blockHeight: 0, channelId: '',
  );
}

class BlockchainException implements Exception {
  final String message;
  const BlockchainException(this.message);
  @override
  String toString() => 'BlockchainException: $message';
}

// ── Providers Riverpod ────────────────────────────────────────────────────────
final blockchainServiceProvider =
    Provider<BlockchainService>((_) => BlockchainService());

final fabricNetworkStatusProvider = FutureProvider<FabricNetworkStatus>(
  (ref) => ref.read(blockchainServiceProvider).getNetworkStatus(),
);
