#import "HBTSPlusAlertController.h"
#import "HBTSPlusPreferences.h"
#import "HBTSPlusTapToOpenController.h"
#import "../api/HBTSNotification.h"
#import "../api/HBTSPlusProviderController.h"
#import "../typestatus-private/HBTSStatusBarAlertServer.h"
#import "../typestatus-private/HBTSStatusBarIconController.h"
#import <SpringBoard/SpringBoard.h>
#import <SpringBoard/SBApplication.h>

@implementation HBTSPlusAlertController

+ (void)sendNotification:(HBTSNotification *)notification {
	// crash if we don’t have required parameters
	NSParameterAssert(notification.content);
	NSParameterAssert(notification.statusBarIconName);
	NSParameterAssert(notification.sourceBundleID);

	// get the enabled state of the provider (if there is one)
	HBTSPlusProvider *provider = [[HBTSPlusProviderController sharedInstance] providerWithAppIdentifier:notification.sourceBundleID];
	BOOL enabled = provider ? [[HBTSPlusProviderController sharedInstance] providerIsEnabled:provider] : YES;

	// determine whether the app is in the foreground
	SpringBoard *app = (SpringBoard *)[UIApplication sharedApplication];
	BOOL inForeground = [app._accessibilityFrontMostApplication.bundleIdentifier isEqualToString:notification.sourceBundleID];

	HBTSPlusPreferences *preferences = [%c(HBTSPlusPreferences) sharedInstance];

	// if we’re disabled, or we’re in the foreground and the user doesn’t want
	// foreground notifications, return
	if (!preferences.enabled || !enabled || (inForeground && !preferences.showWhenInForeground)) {
		return;
	}

	// give the tap to open controller context
	HBTSPlusTapToOpenController *tapToOpenController = [HBTSPlusTapToOpenController sharedInstance];
	tapToOpenController.appIdentifier = notification.sourceBundleID;
	tapToOpenController.actionURL = notification.actionURL;

	dispatch_async(dispatch_get_main_queue(), ^{
		// pass the alert to the appropriate typestatus controller based on the alert
		// type preference
		switch (preferences.alertType) {
			case HBTSPlusAlertTypeIcon:
				[%c(HBTSStatusBarIconController) showIcon:notification.statusBarIconName timeout:-1];
				break;

			case HBTSPlusAlertTypeOverlay:
				[%c(HBTSStatusBarAlertServer) sendAlertWithIconName:notification.statusBarIconName text:notification.content boldRange:notification.boldRange source:notification.sourceBundleID timeout:-1];
				break;
		}
	});
}

+ (void)hide {
	dispatch_async(dispatch_get_main_queue(), ^{
		[%c(HBTSStatusBarAlertServer) hide];
	});
}

@end
