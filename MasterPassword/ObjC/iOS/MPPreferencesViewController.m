//
//  MPPreferencesViewController.m
//  MasterPassword-iOS
//
//  Created by Maarten Billemont on 04/06/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "MPPreferencesViewController.h"
#import "MPiOSAppDelegate.h"
#import "MPAppDelegate_Key.h"
#import "MPAppDelegate_Store.h"

@interface MPPreferencesViewController()

@end

@implementation MPPreferencesViewController

- (void)viewDidLoad {

    self.avatarTemplate.hidden = YES;

    for (int a = 0; a < MPAvatarCount; ++a) {
        UIButton *avatar = [self.avatarTemplate clone];
        avatar.tag = a;
        avatar.hidden = NO;
        avatar.center = CGPointMake(
                self.avatarTemplate.center.x * (a + 1) + self.avatarTemplate.bounds.size.width / 2 * a,
                self.avatarTemplate.center.y );
        [avatar setBackgroundImage:[UIImage imageNamed:PearlString( @"avatar-%d", a )]
                          forState:UIControlStateNormal];
        [avatar setSelectionInSuperviewCandidate:YES isClearable:NO];

        avatar.layer.cornerRadius = avatar.bounds.size.height / 2;
        avatar.layer.shadowColor = [UIColor blackColor].CGColor;
        avatar.layer.shadowOpacity = 1;
        avatar.layer.shadowRadius = 5;
        avatar.backgroundColor = [UIColor clearColor];

        [avatar onHighlightOrSelect:^(BOOL highlighted, BOOL selected) {
            if (highlighted || selected)
                avatar.backgroundColor = self.avatarTemplate.backgroundColor;
            else
                avatar.backgroundColor = [UIColor clearColor];
        }                   options:0];
        [avatar onSelect:^(BOOL selected) {
            if (selected) {
                MPUserEntity *activeUser = [[MPiOSAppDelegate get] activeUserForThread];
                activeUser.avatar = (unsigned)avatar.tag;
                [activeUser.managedObjectContext saveToStore];
            }
        }        options:0];
        avatar.selected = (a == [[MPiOSAppDelegate get] activeUserForThread].avatar);
    }

    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {

    inf(@"Preferences will appear");
    [self.avatarsView autoSizeContent];
    [self.avatarsView enumerateSubviews:^(UIView *subview, BOOL *stop, BOOL *recurse) {
        if (subview.tag && ((UIControl *)subview).selected) {
            [self.avatarsView setContentOffset:CGPointMake( subview.center.x - self.avatarsView.bounds.size.width / 2, 0 )
                                      animated:animated];
        }
    }                           recurse:NO];

    MPUserEntity *activeUser = [[MPiOSAppDelegate get] activeUserForThread];
    self.savePasswordSwitch.on = activeUser.saveKey;
    self.defaultTypeLabel.text = [[MPiOSAppDelegate get].key.algorithm shortNameOfType:activeUser.defaultType];

    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {

    [[LocalyticsSession sharedLocalyticsSession] tagScreen:@"Preferences"];

    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {

    inf(@"Preferences will disappear");
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotate {

    return NO;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {

    return UIInterfaceOrientationPortrait;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([[segue identifier] isEqualToString:@"MP_ChooseType"])
        ((MPTypeViewController *)[segue destinationViewController]).delegate = self;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
    if (cell == self.exportCell)
        [[MPiOSAppDelegate get] export];

    else if (cell == self.changeMPCell) {
        MPUserEntity *activeUser = [[MPiOSAppDelegate get] activeUserForThread];
        [[MPiOSAppDelegate get] changeMasterPasswordFor:activeUser inContext:activeUser.managedObjectContext didResetBlock:nil];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - IASKSettingsDelegate

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController *)sender {

    while ([self.navigationController.viewControllers containsObject:sender])
        [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - MPTypeDelegate

- (void)didSelectType:(MPElementType)type {

    MPUserEntity *activeUser = [[MPiOSAppDelegate get] activeUserForThread];
    activeUser.defaultType = type;
    [activeUser.managedObjectContext saveToStore];

    self.defaultTypeLabel.text = [[MPiOSAppDelegate get].key.algorithm shortNameOfType:activeUser.defaultType];
}

- (MPElementType)selectedType {

    return [[MPiOSAppDelegate get] activeUserForThread].defaultType;
}

#pragma mark - IBActions

- (IBAction)didToggleSwitch:(UISwitch *)sender {

    MPUserEntity *activeUser = [[MPiOSAppDelegate get] activeUserForThread];
    if ((activeUser.saveKey = sender.on))
        [[MPiOSAppDelegate get] storeSavedKeyFor:activeUser];
    else
        [[MPiOSAppDelegate get] forgetSavedKeyFor:activeUser];
    [activeUser.managedObjectContext saveToStore];
}

- (IBAction)settings:(UIBarButtonItem *)sender {

    IASKAppSettingsViewController *vc = [IASKAppSettingsViewController new];
    vc.showDoneButton = NO;

    [self.navigationController pushViewController:vc animated:YES];
    [[LocalyticsSession sharedLocalyticsSession] tagScreen:@"Settings"];
}

@end
