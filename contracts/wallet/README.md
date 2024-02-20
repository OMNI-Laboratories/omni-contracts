# Wallet

A smart contract wallet that is compliant with multiple ERC standards

## WalletStorage

```solidity
struct WalletStorage {
  mapping(bytes32 => bool) hashes;
}
```

## MAGIC_VALUE

```solidity
bytes4 MAGIC_VALUE
```

## UpdateSignatureValidation

```solidity
event UpdateSignatureValidation(bytes32 signedHash, bool validity)
```

_Provides state of signed hash_

## initialize

```solidity
function initialize(address owner, uint256 identifier, string name, string version) external
```

Initializes the VanityWallet with owner and other details.

_Calls the initialization of SignatureWallet._

### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| owner | address | The owner of the wallet. |
| identifier | uint256 | A unique identifier for the wallet. |
| name | string | The name for the EIP712 domain. |
| version | string | The version for the EIP712 domain. |

## isValidSignature

```solidity
function isValidSignature(bytes32 hash, bytes signature) external view returns (bytes4)
```

Validates a given signature according to ERC-1271.

_Returns MAGIC_VALUE if the signature is valid, otherwise returns 0xffffffff._

### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| hash | bytes32 | The hash of the data signed. |
| signature | bytes | The signature to validate. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes4 | bytes4 MAGIC_VALUE if the signature is valid, otherwise returns 0xffffffff. |

## hashValidation

```solidity
function hashValidation(bytes32 hash, bytes signature, bytes32 signedHash, bool validity) external
```

Allows the owner to validate or invalidate a hash.

_Updates the `hashes` mapping to reflect the validity of a hash._

### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| hash | bytes32 | The hash of the data signed. |
| signature | bytes | The signature to authorize this operation. |
| signedHash | bytes32 | The hash to validate or invalidate. |
| validity | bool | Boolean representing the validity of the hash. Emits a {UpdateSignatureValidation} event. |

## receive

```solidity
receive() external payable
```
