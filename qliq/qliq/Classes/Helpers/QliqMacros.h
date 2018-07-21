//
//  QliqMacros.h
//  qliq
//
//  Created by Valerii Lider on 21/01/16.
//
//

#ifndef QliqMacros_h
#define QliqMacros_h

/**
 *  Localization stuff
 */

/*
 Open Terminal and navigate to your project's home directory. Then run this command:
 find ./ -name "*.m" -print0 | xargs -0 genstrings -o en.lproj
 */

#define QliqLocalizedString(str) [NSLocalizedString(str, @"") length] > 0 ? NSLocalizedString(str, @"") : @" "

#define QliqFormatLocalizedString1(fmt, arg1) [NSString stringWithFormat:NSLocalizedString(fmt, @""), arg1]
#define QliqFormatLocalizedString2(fmt, arg1, arg2) [NSString stringWithFormat:NSLocalizedString(fmt, @""), arg1, arg2]
#define QliqFormatLocalizedString3(fmt, arg1, arg2, arg3) [NSString stringWithFormat:NSLocalizedString(fmt, @""), arg1, arg2, arg3]
#define QliqFormatLocalizedString4(fmt, arg1, arg2, arg3, arg4) [NSString stringWithFormat:NSLocalizedString(fmt, @""), arg1, arg2, arg3, arg4]

/**
 *
 */

#define kWeakSelf(selfObject) __block __weak typeof(selfObject) weakSelf = selfObject


/**
 *  Storyboards
 */

#define kDefaultStoryboard  [UIStoryboard storyboardWithName:@"Storyboard" bundle:[NSBundle mainBundle]]
#define kMainStoryboard     [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]]
#define kSettingsStoryboard [UIStoryboard storyboardWithName:@"Settings" bundle:[NSBundle mainBundle]]

#endif /* QliqMacros_h */
