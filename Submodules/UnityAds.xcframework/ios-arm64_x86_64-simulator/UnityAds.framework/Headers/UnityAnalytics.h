#import <UnityAds/UnityAnalyticsAcquisitionType.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  `UnityAnalytics` is a static class with methods for sending analytics events
 */
@interface UnityAnalytics : NSObject

/**
 * Sends an item acquired event to Unity Analytics
 *
 * @param transactionId         Unique Identifier that can be used to identify the transaction in which the item was acquired. It is recommended to use the transactionId from the app store.
 * @param itemId                Identifier for the item that is acquired
 * @param transactionContext    Description about the game context in which the item was acquired. Example : "third_level_shop"
 * @param level                 Developer defined level that the player was on when the item was acquired
 * @param itemType              Developer defined type that the item is grouped into
 * @param amount                Number of items acquired
 * @param balance               Number of items that the player now has after the transaction
 * @param acquisitionType       The type of acquisition : `kUnityAnalyticsAcquisitionTypeSoft` or `kUnityAnalyticsAcquisitionTypePremium`
 */
+ (void)onItemAcquired: (NSString *)transactionId itemId: (NSString *)itemId transactionContext: (NSString *)transactionContext level: (NSString *)level itemType: (NSString *)itemType amount: (float)amount balance: (float)balance acquisitionType: (UnityAnalyticsAcquisitionType)acquisitionType;

/**
 * Send an item spent event to Unity Analyitcs
 *
 * @param transactionId         Unique Identifier that can be used to identify the transaction in which the item was spent. It is recommended to use the transactionId from the app store.
 * @param itemId                Identifier for the item that is spent
 * @param transactionContext    Description about the game context in which the item was spent. Example : "third_level_shop"
 * @param level                 Developer defined level that the player was on when the item was spent
 * @param itemType              Developer defined type that the item is grouped into
 * @param amount                Number of items spent
 * @param balance               Number of items that the player now has after the transaction
 * @param acquisitionType       The type of acquisition : `kUnityAnalyticsAcquisitionTypeSoft` or `kUnityAnalyticsAcquisitionTypePremium`
 */
+ (void)onItemSpent: (NSString *)transactionId itemId: (NSString *)itemId transactionContext: (NSString *)transactionContext level: (NSString *)level itemType: (NSString *)itemType amount: (float)amount balance: (float)balance acquisitionType: (UnityAnalyticsAcquisitionType)acquisitionType;

/**
 * Sends a level fail event to Unity Analytics
 *
 * @param levelIndex    The index for the level that the player failed
 */
+ (void)onLevelFail: (NSString *)levelIndex;

/**
 * Sends a level up event to Unity Analytics
 *
 * @param theNewLevelIndex  The index for the new level that the player just unlocked
 */
+ (void)onLevelUp: (NSString *)theNewLevelIndex;

/**
 * Send an Ad Complete event to Unity Analytics
 *
 * @param placementId   The Placement ID for the Ad
 * @param network       Add network name
 * @param rewarded      Boolean indicating if the Ad was rewarded or not
 */
+ (void)onAdComplete: (NSString *)placementId network: (NSString *)network rewarded: (BOOL)rewarded;

/**
 * Send an In App Purchase Transaction event to Unity Analytics
 *
 * @param productId     The Product Id specified by the developer for a promo
 * @param amount        The price to purchase the promo
 * @param currency      The iso currency code for the amount
 * @param isPromo       A boolean specifying if the transaction came from a promo
 * @param receipt       A json string of containing information about the transaction
 */
+ (void)onIapTransaction: (NSString *)productId amount: (float)amount currency: (NSString *)currency isPromo: (BOOL)isPromo receipt: (NSString *)receipt;

/**
 * Send an analytics event.
 * The dictionary structure must be 100% correct when using this method or the event will not be validated and sent.
 *
 * @param jsonObject    Json dictionary with all necessary fields that will be sent to analytics
 *
 * @note It is strongly encouraged to use a specific event handler so that the event format is correct
 */
+ (void)onEvent: (NSDictionary<NSString *, NSObject *> *)jsonObject;

@end

NS_ASSUME_NONNULL_END
