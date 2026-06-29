import Core
import Types
import Transactions

extension Aptos.Transaction {
    public func entryFunction(
        sender: AccountAddressInput,
        function: MoveFunctionId,
        typeArguments: [TypeArgument]? = nil,
        functionArguments: [FunctionArgumentTypes],
        abi: EntryFunctionABI? = nil,
        options: InputGenerateTransactionOptions? = nil,
        withFeePayer: Bool? = nil
    ) async throws -> SimpleTransaction {
        try await build.simple(
            sender: sender,
            data: InputEntryFunctionData(
                function: function,
                typeArguments: typeArguments,
                functionArguments: functionArguments,
                abi: abi
            ),
            options: options,
            withFeePayer: withFeePayer
        )
    }

    public func transferCoinTransaction(
        sender: AccountAddressInput,
        recipient: AccountAddressInput,
        amount: UInt64,
        coinType: TypeArgument = InputEntryFunctionData.aptosCoinType,
        options: InputGenerateTransactionOptions? = nil,
        withFeePayer: Bool? = nil
    ) async throws -> SimpleTransaction {
        try await build.simple(
            sender: sender,
            data: InputEntryFunctionData.transferCoin(
                recipient: recipient,
                amount: amount,
                coinType: coinType
            ),
            options: options,
            withFeePayer: withFeePayer
        )
    }

    public func transferFungibleAsset(
        sender: AccountAddressInput,
        fungibleAssetMetadataAddress: AccountAddressInput,
        recipient: AccountAddressInput,
        amount: UInt64,
        options: InputGenerateTransactionOptions? = nil,
        withFeePayer: Bool? = nil
    ) async throws -> SimpleTransaction {
        try await build.simple(
            sender: sender,
            data: InputEntryFunctionData.transferFungibleAsset(
                metadataAddress: fungibleAssetMetadataAddress,
                recipient: recipient,
                amount: amount
            ),
            options: options,
            withFeePayer: withFeePayer
        )
    }

    public func transferFungibleAssetBetweenStores(
        sender: AccountAddressInput,
        fromStore: AccountAddressInput,
        toStore: AccountAddressInput,
        amount: UInt64,
        options: InputGenerateTransactionOptions? = nil,
        withFeePayer: Bool? = nil
    ) async throws -> SimpleTransaction {
        try await build.simple(
            sender: sender,
            data: InputEntryFunctionData.transferFungibleAssetBetweenStores(
                fromStore: fromStore,
                toStore: toStore,
                amount: amount
            ),
            options: options,
            withFeePayer: withFeePayer
        )
    }

    public func transferTokenTransaction(
        sender: AccountAddressInput,
        token: FungibleTokenIdentifier,
        recipient: AccountAddressInput,
        amount: UInt64,
        options: InputGenerateTransactionOptions? = nil,
        withFeePayer: Bool? = nil
    ) async throws -> SimpleTransaction {
        try await build.simple(
            sender: sender,
            data: InputEntryFunctionData.transferToken(
                token: token,
                recipient: recipient,
                amount: amount
            ),
            options: options,
            withFeePayer: withFeePayer
        )
    }

    public func transferTokenTransaction(
        sender: AccountAddressInput,
        token: String,
        recipient: AccountAddressInput,
        amount: UInt64,
        options: InputGenerateTransactionOptions? = nil,
        withFeePayer: Bool? = nil
    ) async throws -> SimpleTransaction {
        try await transferTokenTransaction(
            sender: sender,
            token: FungibleTokenIdentifier(token),
            recipient: recipient,
            amount: amount,
            options: options,
            withFeePayer: withFeePayer
        )
    }

    public func createCollectionTransaction(
        sender: AccountAddressInput,
        description: String,
        name: String,
        uri: String,
        collectionOptions: InputEntryFunctionData.DigitalAssetCollectionOptions = .init(),
        options: InputGenerateTransactionOptions? = nil,
        withFeePayer: Bool? = nil
    ) async throws -> SimpleTransaction {
        try await build.simple(
            sender: sender,
            data: InputEntryFunctionData.createCollection(
                description: description,
                name: name,
                uri: uri,
                options: collectionOptions
            ),
            options: options,
            withFeePayer: withFeePayer
        )
    }

    public func mintDigitalAssetTransaction(
        sender: AccountAddressInput,
        collection: String,
        description: String,
        name: String,
        uri: String,
        propertyKeys: [String] = [],
        propertyTypes: [String] = [],
        propertyValues: [[UInt8]] = [],
        options: InputGenerateTransactionOptions? = nil,
        withFeePayer: Bool? = nil
    ) async throws -> SimpleTransaction {
        try await build.simple(
            sender: sender,
            data: InputEntryFunctionData.mintDigitalAsset(
                collection: collection,
                description: description,
                name: name,
                uri: uri,
                propertyKeys: propertyKeys,
                propertyTypes: propertyTypes,
                propertyValues: propertyValues
            ),
            options: options,
            withFeePayer: withFeePayer
        )
    }

    public func transferDigitalAssetTransaction(
        sender: AccountAddressInput,
        digitalAssetAddress: AccountAddressInput,
        recipient: AccountAddressInput,
        digitalAssetType: TypeArgument = InputEntryFunctionData.defaultDigitalAssetType,
        options: InputGenerateTransactionOptions? = nil,
        withFeePayer: Bool? = nil
    ) async throws -> SimpleTransaction {
        try await build.simple(
            sender: sender,
            data: InputEntryFunctionData.transferDigitalAsset(
                digitalAssetAddress: digitalAssetAddress,
                recipient: recipient,
                digitalAssetType: digitalAssetType
            ),
            options: options,
            withFeePayer: withFeePayer
        )
    }

    public func burnDigitalAssetTransaction(
        sender: AccountAddressInput,
        digitalAssetAddress: AccountAddressInput,
        digitalAssetType: TypeArgument = InputEntryFunctionData.defaultDigitalAssetType,
        options: InputGenerateTransactionOptions? = nil,
        withFeePayer: Bool? = nil
    ) async throws -> SimpleTransaction {
        try await build.simple(
            sender: sender,
            data: InputEntryFunctionData.burnDigitalAsset(
                digitalAssetAddress: digitalAssetAddress,
                digitalAssetType: digitalAssetType
            ),
            options: options,
            withFeePayer: withFeePayer
        )
    }

    public func freezeDigitalAssetTransferTransaction(
        sender: AccountAddressInput,
        digitalAssetAddress: AccountAddressInput,
        digitalAssetType: TypeArgument = InputEntryFunctionData.defaultDigitalAssetType,
        options: InputGenerateTransactionOptions? = nil,
        withFeePayer: Bool? = nil
    ) async throws -> SimpleTransaction {
        try await build.simple(
            sender: sender,
            data: InputEntryFunctionData.freezeDigitalAssetTransfer(
                digitalAssetAddress: digitalAssetAddress,
                digitalAssetType: digitalAssetType
            ),
            options: options,
            withFeePayer: withFeePayer
        )
    }

    public func unfreezeDigitalAssetTransferTransaction(
        sender: AccountAddressInput,
        digitalAssetAddress: AccountAddressInput,
        digitalAssetType: TypeArgument = InputEntryFunctionData.defaultDigitalAssetType,
        options: InputGenerateTransactionOptions? = nil,
        withFeePayer: Bool? = nil
    ) async throws -> SimpleTransaction {
        try await build.simple(
            sender: sender,
            data: InputEntryFunctionData.unfreezeDigitalAssetTransfer(
                digitalAssetAddress: digitalAssetAddress,
                digitalAssetType: digitalAssetType
            ),
            options: options,
            withFeePayer: withFeePayer
        )
    }
}
