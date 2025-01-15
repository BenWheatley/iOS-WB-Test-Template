import Foundation

// Would recommend to import SwiftData then prefix with @Model, but the project settings are for iOS 15 and @Model is iOS 17+
struct Asset: Codable, Identifiable {
    let id = UUID() // Not part of the API, this is only used internally
    let assetId: String // API docs claim this can be nil: not actually observed, seems suspicious that it could be in practice
    let name: String? // Observed: can be nil, see test data for "RLUSD"
    let typeIsCrypto: Int32
    let dataQuoteStart: Date?
    let dataQuoteEnd: Date?
    let dataOrderbookStart: Date?
    let dataOrderbookEnd: Date?
    let dataTradeStart: Date?
    let dataTradeEnd: Date?
    let dataSymbolsCount: Int64?
    let volume1HrsUsd: Double?
    let volume1DayUsd: Double?
    let volume1MthUsd: Double?
	let priceUsd: Double? // Note: `Double` is as-specified by API docs, but `Double` is famously a bad choice for anything involving money due to how 1/10th is recurring fraction in base-2. API docs: https://docs.coinapi.io/market-data/rest-api/metadata/list-all-assets
    var isFavorite: Bool = false
    
    // Local properties
    var iconUrl: String {
        "https://s3.eu-central-1.amazonaws.com/bbxt-static-icons/type-id/png_16/4958c92dbddd4936b1f655e5063dc782.png"
    }
    
    enum CodingKeys: String, CodingKey {
        case assetId = "asset_id"
        case name = "name"
        case typeIsCrypto = "type_is_crypto"
        case dataQuoteStart = "data_quote_start"
        case dataQuoteEnd = "data_quote_end"
        case dataOrderbookStart = "data_orderbook_start"
        case dataOrderbookEnd = "data_orderbook_end"
        case dataTradeStart = "data_trade_start"
        case dataTradeEnd = "data_trade_end"
        case dataSymbolsCount = "data_symbols_count"
        case volume1HrsUsd = "volume_1hrs_usd"
        case volume1DayUsd = "volume_1day_usd"
        case volume1MthUsd = "volume_1mth_usd"
        case priceUsd = "price_usd"
    }
}

extension Asset: AutoDecoder {
	static let dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? = {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSX" // Matches the date format in the JSON
		return .formatted(formatter)
	}()
}

extension Asset {
	init?(from coreDataEntity: AssetEntity) {
		if let assetId = coreDataEntity.assetId {
			self.assetId = assetId
		} else {
			// API docs claim this can be nil: not actually observed in any responses I've seen, I think the app wouldn't function if this happens in practice, so fail this particular init
			debugPrint("CoreData's AssetEntity is missing assetId: \(coreDataEntity) - skipping, worth checking how this happened because (despite being optional in API docs) I don't see how this would make sense for the data schema")
			return nil
		}
		name = coreDataEntity.name
		typeIsCrypto = coreDataEntity.typeIsCrypto
		dataQuoteStart = coreDataEntity.dataQuoteStart
		dataQuoteEnd = coreDataEntity.dataQuoteEnd
		dataOrderbookStart = coreDataEntity.dataOrderbookStart
		dataOrderbookEnd = coreDataEntity.dataOrderbookEnd
		dataTradeStart = coreDataEntity.dataTradeStart
		dataTradeEnd = coreDataEntity.dataTradeEnd
		
		// This weirdness because the "optional" flag in CoreData isn't enough, it has to *not* "Use Scalar Type":
		dataSymbolsCount = coreDataEntity.dataSymbolsCount?.int64Value
		volume1HrsUsd = coreDataEntity.volume1HrsUsd?.doubleValue
		volume1DayUsd = coreDataEntity.volume1DayUsd?.doubleValue
		volume1MthUsd = coreDataEntity.volume1MthUsd?.doubleValue
		priceUsd = coreDataEntity.priceUsd?.doubleValue
		
		isFavorite = coreDataEntity.isFavorite
	}
}
