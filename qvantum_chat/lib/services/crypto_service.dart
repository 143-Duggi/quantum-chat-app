import 'dart:convert';
import 'dart:typed_data';
import 'package:xkyber_crypto/xkyber_crypto.dart';

class CryptoService {
  // Generate Kyber keypair
  KeyPairResult generateKeyPair() {
    final keypair = KyberKeyPair.generate();
    
    return KeyPairResult(
      publicKey: keypair.publicKey,
      secretKey: keypair.secretKey,
      publicKeyBase64: base64Encode(keypair.publicKey),
      secretKeyBase64: base64Encode(keypair.secretKey),
    );
  }

  // Encapsulate to generate shared secret
  EncapsulationResult encapsulate(Uint8List publicKey) {
    final result = KyberKEM.encapsulate(publicKey);
    
    return EncapsulationResult(
      ciphertext: result.ciphertextKEM,
      sharedSecret: result.sharedSecret,
      ciphertextBase64: base64Encode(result.ciphertextKEM),
      sharedSecretBase64: base64Encode(result.sharedSecret),
    );
  }

  // Decapsulate to recover shared secret
  Uint8List decapsulate(Uint8List ciphertext, Uint8List secretKey) {
    return KyberKEM.decapsulate(ciphertext, secretKey);
  }

  // Generate symmetric key from shared secret
  Future<Uint8List> generateSymmetricKey() async {
    return await XKyberCrypto.generateSymmetricKey();
  }

  // Encrypt message with AES-GCM
  Future<String> encryptMessage(String plaintext, Uint8List key) async {
    return await XKyberCrypto.symmetricEncrypt(plaintext, key);
  }

  // Decrypt message with AES-GCM
  Future<String> decryptMessage(String ciphertext, Uint8List key) async {
    return await XKyberCrypto.symmetricDecrypt(ciphertext, key);
  }
}

class KeyPairResult {
  final Uint8List publicKey;
  final Uint8List secretKey;
  final String publicKeyBase64;
  final String secretKeyBase64;

  KeyPairResult({
    required this.publicKey,
    required this.secretKey,
    required this.publicKeyBase64,
    required this.secretKeyBase64,
  });
}

class EncapsulationResult {
  final Uint8List ciphertext;
  final Uint8List sharedSecret;
  final String ciphertextBase64;
  final String sharedSecretBase64;

  EncapsulationResult({
    required this.ciphertext,
    required this.sharedSecret,
    required this.ciphertextBase64,
    required this.sharedSecretBase64,
  });
}
