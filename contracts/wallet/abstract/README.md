# Ownable

The initial owner is set to the deployer address and can be transferred.

_Contract module which provides a basic access control mechanism.
     There is an owner account that can be granted exclusive access to specific functions._

## OwnableStorage

```solidity
struct OwnableStorage {
  address _owner;
  address _pendingOwner;
}
```

## OwnableUnauthorizedAccount

```solidity
error OwnableUnauthorizedAccount()
```

_The caller account is not authorized to perform an operation._

## OwnableInvalidOwner

```solidity
error OwnableInvalidOwner(address owner)
```

_The owner is not a valid owner account. (eg. `address(0)`)_

## OwnershipTransferStarted

```solidity
event OwnershipTransferStarted(address previousOwner, address newOwner)
```

_The owner is to be swapped out, the pending owner has been updated_

## OwnershipTransferred

```solidity
event OwnershipTransferred(address previousOwner, address newOwner)
```

_The owner is swapped out, the pending owner has been upgraded to the new owner_

## __Ownable_init

```solidity
function __Ownable_init(address initialOwner) internal
```

Initializes the contract with the deployer as the initial owner.

_Sets the initial owner of the contract to the provided address._

### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| initialOwner | address | The address to be set as the initial owner. |

## __Ownable_init_unchained

```solidity
function __Ownable_init_unchained(address initialOwner) internal
```

## onlyOwner

```solidity
modifier onlyOwner(bytes32 hash, bytes signature)
```

Ensures that a function is called only by the owner.

_Modifier that throws `OwnableUnauthorizedAccount` if called by any account other than the owner._

### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| hash | bytes32 | The hash of the payload. |
| signature | bytes | The signature proving the owner's consent. |

## transferOwnership

```solidity
function transferOwnership(address newOwner, bytes32 hash, bytes signature) external virtual
```

Transfers ownership of the contract to a new account.

_This is the intermidary step and needs to be confirmed by the new owner._

### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newOwner | address | The address of the new owner. |
| hash | bytes32 | The hash of the payload. |
| signature | bytes | The signature proving the current owner's consent. Emits a {OwnershipTransferStarted} event. |

## acceptOwnership

```solidity
function acceptOwnership(bytes32 hash, bytes signature) external virtual
```

Finalizes the ownership transfer.

_Accepts the ownership transfer by the new owner._

### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| hash | bytes32 | The hash of the payload. |
| signature | bytes | The signature proving the new owner's consent. Emits a {OwnershipTransferred} event. |

## owner

```solidity
function owner() public view virtual returns (address)
```

Returns the address of the current owner.

_Reads the owner's address from the Ownable storage._

### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | address The address of the current owner. |

## pendingOwner

```solidity
function pendingOwner() public view virtual returns (address)
```

Returns the address of the pending owner.

_Reads the pending owner's address from the Ownable storage._

### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | address The address of the pending owner. |

## checkSignature

```solidity
function checkSignature(address signer, bytes32 hash, bytes signature) internal view virtual returns (bool)
```

Checks if the provided signature is valid and signed by the expected signer.

_Verifies the signer's address against the provided hash and signature._

### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| signer | address | The address of the expected signer. |
| hash | bytes32 | The hash of the payload. |
| signature | bytes | The signature to validate. |

### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | bool True if the signature is valid, false otherwise. |

# SignatureWallet

This contract allows executing transactions securely using EIP712 signatures.

_Abstract contract providing functionality for wallet operations via signatures._

## SignatureWalletStorage

```solidity
struct SignatureWalletStorage {
  uint256 _identifier;
}
```

## CallType

_Calls are executed by the wallet, or functionality is delegated out_

```solidity
enum CallType {
  call,
  delegate
}
```

## invalidPayload

```solidity
error invalidPayload()
```

_The payload arrays are not equal length_

## invalidCallType

```solidity
error invalidCallType()
```

_The type is not `call` or `delegatecall`_

## invalidTimestamp

```solidity
error invalidTimestamp()
```

_The timestamp has expired_

## reach

```solidity
bytes reach
```

## __SignatureWallet_init

```solidity
function __SignatureWallet_init(address owner, uint256 identifier, string name, string version) internal
```

Initializes the SignatureWallet contract.

_Sets up EIP712 domain and initializes the ownable contract with the given owner._

### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| owner | address | The address of the initial owner. |
| identifier | uint256 | Unique identifier for the wallet. |
| name | string | Name for the EIP712 domain. |
| version | string | Version for the EIP712 domain. |

## __SignatureWallet_init_unchained

```solidity
function __SignatureWallet_init_unchained(uint256 identifier) internal
```

## execute

```solidity
function execute(uint256 timestamp, bytes32 hash, bytes signature, bytes payloads) external
```

Executes a transaction using a signature for authorization.

_Processes calls or delegate calls based on decoded payload._

### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| timestamp | uint256 | The timestamp for the transaction. |
| hash | bytes32 | The hash of the transaction. |
| signature | bytes | The signature authorizing the transaction. |
| payloads | bytes | The encoded data for the transaction. |

## getNonce

```solidity
function getNonce() public view virtual returns (uint256)
```

Retrieves the current nonce for the wallet.

_The nonce is used to prevent replay attacks by ensuring each transaction is unique.
This function is a public view function, allowing external entities to determine the next valid nonce value._

### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256 The current nonce value for the wallet. |

## getIdentifier

```solidity
function getIdentifier() public view virtual returns (uint256)
```

Retrieves the unique identifier for the wallet.

_This identifier is used to distinguish this wallet within the ecosystem and may be used in constructing unique transaction hashes.
This function is a public view function, allowing external entities to access the wallet's identifier._

### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256 The unique identifier of the wallet. |

## OwnableUnauthorizedAccount

```solidity
error OwnableUnauthorizedAccount()
```

_The caller account is not authorized to perform an operation._

## OwnableInvalidOwner

```solidity
error OwnableInvalidOwner(address owner)
```

_The owner is not a valid owner account. (eg. `address(0)`)_

## OwnershipTransferStarted

```solidity
event OwnershipTransferStarted(address previousOwner, address newOwner)
```

_The owner is to be swapped out, the pending owner has been updated_

## OwnershipTransferred

```solidity
event OwnershipTransferred(address previousOwner, address newOwner)
```

_The owner is swapped out, the pending owner has been upgraded to the new owner_

## OwnableStorage

_The owner and pending owner addresses are held in storage_

```solidity
struct OwnableStorage {
  address _owner;
  address _pendingOwner;
}
```

## invalidPayload

```solidity
error invalidPayload()
```

_The payload arrays are not equal length_

## invalidCallType

```solidity
error invalidCallType()
```

_The type is not `call` or `delegatecall`_

## invalidTimestamp

```solidity
error invalidTimestamp()
```

_The timestamp has expired_

## CallType

_Calls are executed by the wallet, or functionality is delegated out_

```solidity
enum CallType {
  call,
  delegate
}
```
