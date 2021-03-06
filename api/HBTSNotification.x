#import "HBTSNotification.h"
#import "../typestatus-private/HBTSStatusBarAlertServer.h"

static NSString *const kHBTSMessageIconNameKey = @"IconName";
static NSString *const kHBTSMessageContentKey = @"Content";
static NSString *const kHBTSMessageBoldRangeKey = @"BoldRange";
static NSString *const kHBTSMessageDirectionKey = @"Direction";
static NSString *const kHBTSMessageSourceKey = @"Source";

static NSString *const kHBTSMessageTimeoutKey = @"Duration";
static NSString *const kHBTSMessageSendDateKey = @"Date";

static NSString *const kHBTSPlusActionURLKey = @"ActionURL";

@implementation HBTSNotification

#pragma mark - NSObject

- (instancetype)init {
	self = [super init];

	if (self) {
		// set defaults for things that don’t have a nil default
		_boldRange = NSMakeRange(0, 0);
		_date = [NSDate date];
	}

	return self;
}

- (instancetype)initWithType:(HBTSMessageType)type sender:(NSString *)sender iconName:(NSString *)iconName {
	self = [self init];

	if (self) {
		_content = [%c(HBTSStatusBarAlertServer) textForType:type sender:sender boldRange:&_boldRange];
		_statusBarIconName = iconName;
	}

	return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
	self = [self init];

	if (self) {
		// deserialise the easy stuff
		_sourceBundleID = [dictionary[kHBTSMessageSourceKey] copy];
		_content = [dictionary[kHBTSMessageContentKey] copy];
		_statusBarIconName = [dictionary[kHBTSMessageIconNameKey] copy];

		if (dictionary[kHBTSMessageSendDateKey]) {
			id date = dictionary[kHBTSMessageSendDateKey];

			// the date will be serialized to an NSNumber if it’s sent in an IPC
			// message
			if ([date isKindOfClass:NSNumber.class]) {
				_date = [NSDate dateWithTimeIntervalSince1970:((NSNumber *)date).doubleValue];
			} else if ([date isKindOfClass:NSDate.class]) {
				_date = [date copy];
			}
		}

		if (![dictionary[kHBTSPlusActionURLKey] isEqualToString:@""]) {
			_actionURL = [NSURL URLWithString:dictionary[kHBTSPlusActionURLKey]];
		}

		// deserialize the bold range to an NSRange
		NSArray <NSNumber *> *boldRangeArray = dictionary[kHBTSMessageBoldRangeKey];
		_boldRange = NSMakeRange(boldRangeArray[0].unsignedIntegerValue, boldRangeArray[1].unsignedIntegerValue);
	}

	return self;
}

#pragma mark - Serialization

- (NSString *)_contentWithBoldRange:(out NSRange *)boldRange {
	// we should never end up with nothing to return. crash if so
	NSAssert(_content, @"No notification content found");
	NSAssert(_content.length > 0, @"No notification content found");

	// grab the bold range, and return the content
	*boldRange = _boldRange;
	return _content;
}

- (NSDictionary *)dictionaryRepresentation {
	// grab the content and bold range
	NSRange boldRange = NSMakeRange(0, 0);
	NSString *content = [self _contentWithBoldRange:&boldRange];

	NSParameterAssert(_sourceBundleID);
	NSParameterAssert(_date);

	// return serialized dictionary
	return @{
		kHBTSMessageSourceKey: _sourceBundleID,
		kHBTSMessageContentKey: content,
		kHBTSMessageBoldRangeKey: @[ @(boldRange.location), @(boldRange.length) ],
		kHBTSMessageIconNameKey: _statusBarIconName ?: @"",
		kHBTSMessageSendDateKey: @(_date.timeIntervalSince1970),
		kHBTSPlusActionURLKey: _actionURL ? _actionURL.absoluteString : @""
	};
}

@end
