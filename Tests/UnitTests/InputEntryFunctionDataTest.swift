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
}
