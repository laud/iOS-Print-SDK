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
@property (strong, nonatomic) SCNNode *cameraNode;

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
    
    [[scene rootNode] enumerateChildNodesUsingBlock:^(SCNNode *node, BOOL *stop){
//        SCNMaterial *material = [[SCNMaterial alloc] init];
//        material.litPerPixel = NO;
//        material.diffuse.wrapS = SCNWrapModeRepeat;
//        material.diffuse.wrapT = SCNWrapModeRepeat;
//        NSLog(@"%@", [node.geometry geometrySourcesForSemantic:SCNGeometrySourceSemanticTexcoord]);
//        material.diffuse.contents = [UIImage imageNamed:@"quality"];
//        node.geometry.materials = @[material];
    }];
    
    // create and add a camera to the scene
    self.cameraNode = [SCNNode node];
    self.cameraNode.camera = [SCNCamera camera];
    self.cameraNode.camera.zFar = 300;
    
    [scene.rootNode addChildNode:self.cameraNode];
    
    // place the camera
    self.cameraNode.position = SCNVector3Make(0,0,120);
//    self.cameraNode.position = SCNVector3Make(43.628616,71.896751,42.655663);
//    self.cameraNode.rotation = SCNVector4Make(0,-0.7,0,1.616743);
//    self.cameraNode.eulerAngles = SCNVector3Make(-1.61009312,0.0242882688,-0.191921934);
    
    // create and add a light to the scene
    SCNNode *lightNode = [SCNNode node];
    lightNode.light = [SCNLight light];
    lightNode.light.type = SCNLightTypeOmni;
    lightNode.position = SCNVector3Make(0, -10, 10);
    [scene.rootNode addChildNode:lightNode];
    
    // create and add an ambient light to the scene
    SCNNode *ambientLightNode = [SCNNode node];
    ambientLightNode.light = [SCNLight light];
    ambientLightNode.light.type = SCNLightTypeAmbient;
    ambientLightNode.light.color = [UIColor darkGrayColor];
    [scene.rootNode addChildNode:ambientLightNode];
    
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

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesMoved:touches withEvent:event];
    
}



@end
