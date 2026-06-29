
# Aptos Swift SDK
![Swift](https://img.shields.io/badge/Swift-5.0-orange) ![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20visionOS-blue) ![Build Status](https://img.shields.io/github/actions/workflow/status/ALCOVE-LAB/aptos-swift-sdk/swift.yml?branch=main)


## Installing the Swift SDk

```swift
.package(url: "https://github.com/ALCOVE-LAB/aptos-swift-sdk.git", branch: "main")
```

## Using the Swift SDk

### Creating a client
You can create a client by importing the aptos-swift-sdk, and createing a `Client`

```swift
import Aptos

let client = Aptos(aptosConfig: .devnet)

```
You can configure the network with the AptosConfig.Network, or use a preexisting AptosConfig.devnet, AptosConfig.testnet, or AptosConfig.mainnet

### Creating a private key
You can create a new Ed25519 account’s private key by calling Account.generate().

```swift
let account = Account.generate()
```

Derive from private key
```swift

let privateKey = try Ed25519PrivateKey("myEd25519privatekeystring")
// or
let singleKeyPrivateKey = try Secp256k1PrivateKey(Secp256k1.privateKey)

let newAccount: Account.Ed25519Account = try Account.fromPrivateKey(privateKey)
let singleKeyAccount: Account.SingleKeyAccount = try Account.fromPrivateKey(singleKeyPrivateKey)
```

Derive from path
```swift
let path = "m/44'/637'/0'/0'/1"
let mnemonic = "various float stumble..."
let newAccount = try Account.fromDerivationPath(Wallet.path, mnemonic: Wallet.mnemonic)
```

### Funding accounts
You can create and fund an account with a faucet on any network that is not mainnet
```swift
let account = Account.generate()
let txn = try await client.faucet.fundAccount(accountAddress: account.accountAddress, amount: 100_000_000)
```

### Sending a transaction
You can send a AptosCoin via a transaction

```swift
let txn: TransactionResponse
let senderAccount = Account.generate()
_ = try await aptos.faucet.fundAccount(accountAddress: senderAccount.accountAddress, amount: 100_000_000)
let bob = Account.generate()
// Build transaction
let rawTxn = try await aptos.transaction.build.simple(
    sender: senderAccount.accountAddress,
    data: InputEntryFunctionData(
        function: "0x1::aptos_account::transfer",
        functionArguments: [bob.accountAddress, 100]
    )
)
// Sign 
let authenticator = try await aptos.transaction.sign.transaction(
    signer: senderAccount,
    transaction: rawTxn
)
// Submit 
let response = try await aptos.transaction.submit.simple(
    transaction: rawTxn,
    senderAuthenticator: authenticator
)
// Wait
txn = try await aptos.transaction.waitForTransaction(transactionHash: response.hash)
// Read
let transaction = try await aptos.transaction.getTransactionByHash(txn.hash)

```

### Transferring coins and fungible assets
The SDK also provides TypeScript SDK-style helpers for standard Coin and Fungible Asset transfers.

```swift
// Automatically dispatches to legacy Coin transfer when token contains "::",
// otherwise treats token as a Fungible Asset metadata address.
let tokenTxn = try await aptos.transaction.transferTokenTransaction(
    sender: senderAccount.accountAddress,
    token: "0x1::aptos_coin::AptosCoin",
    recipient: bob.accountAddress,
    amount: 100
)

// Transfer APT, or pass coinType for another legacy Coin type.
let coinTxn = try await aptos.transaction.transferCoinTransaction(
    sender: senderAccount.accountAddress,
    recipient: bob.accountAddress,
    amount: 100
)

// Transfer a Fungible Asset from the sender's primary store.
let faTxn = try await aptos.transaction.transferFungibleAsset(
    sender: senderAccount.accountAddress,
    fungibleAssetMetadataAddress: "0x...",
    recipient: bob.accountAddress,
    amount: 100
)

// Call any entry function directly for custom contracts.
let contractTxn = try await aptos.transaction.entryFunction(
    sender: senderAccount.accountAddress,
    function: "0x1::aptos_account::transfer",
    functionArguments: [bob.accountAddress, 100]
)
```

### Creating and trading digital assets
For Aptos Digital Asset NFTs, the SDK mirrors the official TypeScript SDK helpers for collection creation, minting, object transfer, burn, freeze, and unfreeze transactions.

```swift
// Create a Digital Asset collection.
let collectionTxn = try await aptos.transaction.createCollectionTransaction(
    sender: senderAccount.accountAddress,
    description: "Collection description",
    name: "Collection name",
    uri: "https://example.com/collection.json"
)

// Mint an NFT into the collection.
let mintTxn = try await aptos.transaction.mintDigitalAssetTransaction(
    sender: senderAccount.accountAddress,
    collection: "Collection name",
    description: "Token description",
    name: "Token name",
    uri: "https://example.com/token.json"
)

// Transfer the NFT object to another account.
let transferTxn = try await aptos.transaction.transferDigitalAssetTransaction(
    sender: senderAccount.accountAddress,
    digitalAssetAddress: "0x...",
    recipient: bob.accountAddress
)
```

### Testing
To run the SDK tests, simply run from the root of this repository:

> Note: for a better experience, make sure there is no aptos local node process up and running (can check if there is a ?process running on port 8080).

```swift
swift test
```
