//
//  OL3DCaseViewController.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 02/10/15.
//  Copyright © 2015 Deon Botha. All rights reserved.
//

#import "OL3DCaseViewController.h"
#import "OLKiteUtils.h"

@import SceneKit;

@interface OL3DCaseViewController ()
@property (weak, nonatomic) IBOutlet SCNView *scene;

@end

@implementation OL3DCaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];

//    NSURL *caseUrl = [NSURL URLWithString:[[OLKiteUtils kiteBundle] pathForResource:@"case.scnassets/case_ip5" ofType:@"dae"]];
//    
//    
//    SCNSceneSource *sceneSource = [SCNSceneSource sceneSourceWithURL:caseUrl options:nil];
//    
//    // Get reference to the phone node
//    SCNNode *phone2 = [sceneSource entryWithIdentifier:@"test" withClass:[SCNGeometry class]];
//    SCNNode *phone = [[sceneSource entriesPassingTest:^BOOL(id entry, NSString *identifier, BOOL *stop){
//        return YES;
//    }] firstObject];
    
    // Create a new scene
    SCNScene *scene = [SCNScene sceneNamed:@"case_ip5.dae"];
    
    // create and add a camera to the scene
    SCNNode *cameraNode = [SCNNode node];
    cameraNode.camera = [SCNCamera camera];
    [scene.rootNode addChildNode:cameraNode];
    
    // place the camera
    cameraNode.position = SCNVector3Make(0, 0, 100);
    
    // create and add a light to the scene
    SCNNode *lightNode = [SCNNode node];
    lightNode.light = [SCNLight light];
    lightNode.light.type = SCNLightTypeOmni;
    lightNode.position = SCNVector3Make(0, 10, 10);
    [scene.rootNode addChildNode:lightNode];
    
    // create and add an ambient light to the scene
    SCNNode *ambientLightNode = [SCNNode node];
    ambientLightNode.light = [SCNLight light];
    ambientLightNode.light.type = SCNLightTypeAmbient;
    ambientLightNode.light.color = [UIColor darkGrayColor];
    [scene.rootNode addChildNode:ambientLightNode];
    
    // Add our cube to the scene
//    [scene.rootNode addChildNode:phone];
    
    SCNView *scnView = self.scene;
    
    // set the scene to the view
    scnView.scene = scene;
    
    // allows the user to manipulate the camera
    scnView.allowsCameraControl = YES;
    
#ifdef DEBUG
    // show statistics such as fps and timing information
    scnView.showsStatistics = YES;
#endif
    
    // configure the view
    scnView.backgroundColor = [UIColor clearColor];
}



@end
