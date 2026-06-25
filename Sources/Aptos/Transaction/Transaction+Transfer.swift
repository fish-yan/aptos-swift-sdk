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
            data: .transferCoin(
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
            data: .transferFungibleAsset(
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
            data: .transferFungibleAssetBetweenStores(
                fromStore: fromStore,
                toStore: toStore,
                amount: amount
            ),
            options: options,
            withFeePayer: withFeePayer
        )
    }
}
