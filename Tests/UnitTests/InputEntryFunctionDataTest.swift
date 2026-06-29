import XCTest
import Core
import Transactions

final class InputEntryFunctionDataTest: XCTestCase {
    func testTransferCoinDataMatchesTypeScriptSDKShape() {
        let data = InputEntryFunctionData.transferCoin(
            recipient: "0xb0b",
            amount: 100
        )

        XCTAssertEqual(data.function, "0x1::aptos_account::transfer_coins")
        XCTAssertEqual(data.typeArguments?.first as? String, InputEntryFunctionData.aptosCoinType)
        XCTAssertEqual(data.functionArguments.count, 2)
        XCTAssertEqual(data.abi?.typeParameters.count, 1)
        XCTAssertEqual(data.abi?.parameters, [.Address, .U64])
    }

    func testTransferFungibleAssetDataMatchesPrimaryStoreShape() throws {
        let data = InputEntryFunctionData.transferFungibleAsset(
            metadataAddress: "0xface",
            recipient: "0xb0b",
            amount: 10
        )

        XCTAssertEqual(data.function, "0x1::primary_fungible_store::transfer")
        XCTAssertEqual(data.typeArguments?.first as? String, InputEntryFunctionData.fungibleAssetMetadataType)
        XCTAssertEqual(data.functionArguments.count, 3)
        XCTAssertEqual(data.abi?.typeParameters.count, 1)
        XCTAssertEqual(
            data.abi?.parameters,
            [
                .Struct(.object(.Generic(0))),
                .Address,
                .U64
            ]
        )
    }

    func testTransferFungibleAssetBetweenStoresDataMatchesDispatchableStoreShape() {
        let data = InputEntryFunctionData.transferFungibleAssetBetweenStores(
            fromStore: "0xcafe",
            toStore: "0xbeef",
            amount: 25
        )

        XCTAssertEqual(data.function, "0x1::dispatchable_fungible_asset::transfer")
        XCTAssertEqual(data.typeArguments?.first as? String, InputEntryFunctionData.fungibleStoreType)
        XCTAssertEqual(data.functionArguments.count, 3)
        XCTAssertEqual(data.abi?.typeParameters.count, 1)
        XCTAssertEqual(
            data.abi?.parameters,
            [
                .Struct(.object(.Generic(0))),
                .Address,
                .U64
            ]
        )
    }

    func testFungibleTokenIdentifierDetectsCoinTypeStrings() {
        XCTAssertEqual(
            FungibleTokenIdentifier.standard(for: "0x1::aptos_coin::AptosCoin"),
            .coin
        )
    }

    func testFungibleTokenIdentifierDetectsFungibleAssetMetadataAddresses() {
        XCTAssertEqual(
            FungibleTokenIdentifier.standard(for: "0xface"),
            .fungibleAsset
        )
    }

    func testTransferTokenDataUsesCoinTransferForLegacyCoinType() {
        let data = InputEntryFunctionData.transferToken(
            token: "0x1::aptos_coin::AptosCoin",
            recipient: "0xb0b",
            amount: 100
        )

        XCTAssertEqual(data.function, "0x1::aptos_account::transfer_coins")
        XCTAssertEqual(data.typeArguments?.first as? String, "0x1::aptos_coin::AptosCoin")
        XCTAssertEqual(data.functionArguments.count, 2)
        XCTAssertEqual(data.abi?.parameters, [.Address, .U64])
    }

    func testTransferTokenDataUsesFungibleAssetTransferForMetadataAddress() {
        let data = InputEntryFunctionData.transferToken(
            token: "0xface",
            recipient: "0xb0b",
            amount: 100
        )

        XCTAssertEqual(data.function, "0x1::primary_fungible_store::transfer")
        XCTAssertEqual(data.typeArguments?.first as? String, InputEntryFunctionData.fungibleAssetMetadataType)
        XCTAssertEqual(data.functionArguments.count, 3)
        XCTAssertEqual(
            data.abi?.parameters,
            [
                .Struct(.object(.Generic(0))),
                .Address,
                .U64
            ]
        )
    }

    func testCreateCollectionDataMatchesDigitalAssetShape() {
        let data = InputEntryFunctionData.createCollection(
            description: "Collection description",
            name: "Collection name",
            uri: "https://example.com/collection.json"
        )

        XCTAssertEqual(data.function, "0x4::aptos_token::create_collection")
        XCTAssertNil(data.typeArguments)
        XCTAssertEqual(data.functionArguments.count, 15)
        XCTAssertEqual(data.abi?.typeParameters.count, 0)
        XCTAssertEqual(
            data.abi?.parameters,
            [
                .Struct(.string),
                .U64,
                .Struct(.string),
                .Struct(.string),
                .Bool,
                .Bool,
                .Bool,
                .Bool,
                .Bool,
                .Bool,
                .Bool,
                .Bool,
                .Bool,
                .U64,
                .U64
            ]
        )
    }

    func testMintDigitalAssetDataMatchesDigitalAssetShape() {
        let data = InputEntryFunctionData.mintDigitalAsset(
            collection: "Collection name",
            description: "Token description",
            name: "Token name",
            uri: "https://example.com/token.json",
            propertyKeys: ["rarity"],
            propertyTypes: ["0x1::string::String"],
            propertyValues: [[1, 2, 3]]
        )

        XCTAssertEqual(data.function, "0x4::aptos_token::mint")
        XCTAssertNil(data.typeArguments)
        XCTAssertEqual(data.functionArguments.count, 7)
        XCTAssertEqual(data.abi?.typeParameters.count, 0)
        XCTAssertEqual(
            data.abi?.parameters,
            [
                .Struct(.string),
                .Struct(.string),
                .Struct(.string),
                .Struct(.string),
                .Vector(.Struct(.string)),
                .Vector(.Struct(.string)),
                .Vector(.Vector(.U8))
            ]
        )
    }

    func testTransferDigitalAssetDataMatchesObjectTransferShape() {
        let data = InputEntryFunctionData.transferDigitalAsset(
            digitalAssetAddress: "0xface",
            recipient: "0xb0b"
        )

        XCTAssertEqual(data.function, "0x1::object::transfer")
        XCTAssertEqual(data.typeArguments?.first as? String, InputEntryFunctionData.defaultDigitalAssetType)
        XCTAssertEqual(data.functionArguments.count, 2)
        XCTAssertEqual(data.abi?.typeParameters.first?.constraints, [.key])
        XCTAssertEqual(
            data.abi?.parameters,
            [
                .Struct(.object(.Generic(0))),
                .Address
            ]
        )
    }

    func testBurnDigitalAssetDataMatchesDigitalAssetObjectShape() {
        let data = InputEntryFunctionData.burnDigitalAsset(digitalAssetAddress: "0xface")

        XCTAssertEqual(data.function, "0x4::aptos_token::burn")
        XCTAssertEqual(data.typeArguments?.first as? String, InputEntryFunctionData.defaultDigitalAssetType)
        assertDigitalAssetObjectABI(data.abi)
    }

    func testFreezeDigitalAssetTransferDataMatchesDigitalAssetObjectShape() {
        let data = InputEntryFunctionData.freezeDigitalAssetTransfer(digitalAssetAddress: "0xface")

        XCTAssertEqual(data.function, "0x4::aptos_token::freeze_transfer")
        XCTAssertEqual(data.typeArguments?.first as? String, InputEntryFunctionData.defaultDigitalAssetType)
        assertDigitalAssetObjectABI(data.abi)
    }

    func testUnfreezeDigitalAssetTransferDataMatchesDigitalAssetObjectShape() {
        let data = InputEntryFunctionData.unfreezeDigitalAssetTransfer(digitalAssetAddress: "0xface")

        XCTAssertEqual(data.function, "0x4::aptos_token::unfreeze_transfer")
        XCTAssertEqual(data.typeArguments?.first as? String, InputEntryFunctionData.defaultDigitalAssetType)
        assertDigitalAssetObjectABI(data.abi)
    }

    private func assertDigitalAssetObjectABI(
        _ abi: EntryFunctionABI?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(abi?.typeParameters.first?.constraints, [.key], file: file, line: line)
        XCTAssertEqual(
            abi?.parameters,
            [
                .Struct(.object(.Generic(0)))
            ],
            file: file,
            line: line
        )
    }
}
