//
//  MVAGraph.m
//  VisitBCN
//
//  Created by Mauro Vime Castillo on 04/09/14.
//  Copyright (c) 2014 Mauro Vime Castillo. All rights reserved.
//

#import "MVAGraph.h"
#import <float.h>
#import <math.h>
#import "MVAAlgorithms.h"
#import "MVApair.h"

@interface MVAGraph ()

@property MVAPath *path;
@property int count;

@end

@implementation MVAGraph

-(MVAPath *)computePathFromNodes:(NSArray *)originNodes toNode:(NSMutableDictionary *)destiniNodes withAlgorithmID:(int)identifier andOCoords:(CLLocationCoordinate2D)oCoords andDest:(MVAPunInt *)punInt
{
    self.count = 0;
    self.path = nil;
    if (identifier == 1) { // DIJKSTRA
        NSNumber *infinity = [NSNumber numberWithDouble:DBL_MAX];
        MVAAlgorithms *alg = [[MVAAlgorithms alloc] init];
        alg.viewController = self.viewController;
        alg.nodes = [self.nodes mutableCopy];
        alg.edgeList = self.edgeList;
        alg.type = self.type;
        alg.dataBus = self.dataBus;
        alg.dataFGC = self.dataFGC;
        alg.dataTMB = self.dataTMB;
        alg.openNodes = [[MVAPriorityQueue alloc] initWithCapacity:[self.nodes count]];
        alg.cal = self.cal;
        for (MVANode *node in self.nodes) {
            node.open = NO;
            node.pathEdges = [[NSMutableArray alloc] init];
            node.pathNodes = [[NSMutableArray alloc] init];
            if ([originNodes containsObject:[NSNumber numberWithInt:node.identificador]]) {
                double sec_rep = [self initTime];
                double dist = [self distanceForCoordinates:oCoords
                                            andCoordinates:CLLocationCoordinate2DMake(node.stop.latitude, node.stop.longitude)];
                double walkingSpeed = [self loadWalkingSpeed];
                sec_rep += ((dist * 1.2) / walkingSpeed);
                
                if (self.type == 1) {
                    node.pathNodes = [[NSMutableArray alloc] init];
                    node.pathEdges = [[NSMutableArray alloc] init];
                    node.distance = [NSNumber numberWithDouble:sec_rep];
                }
                else {
                    node.pathNodes = [[NSMutableArray alloc] init];
                    node.pathEdges = [[NSMutableArray alloc] init];
                    MVACalendar *cal = [self.dataTMB getCurrentCalendarforSubway:NO];
                    double freq = [self.dataBus frequencieForStop:node.stop andTime:sec_rep andCalendar:cal.serviceID];
                    node.distance = [NSNumber numberWithDouble:(sec_rep + freq)];
                }
                MVAPair *p = [[MVAPair alloc] init];
                p.first = [node.distance doubleValue];
                p.second = node.identificador;
                [alg.openNodes addObject:p];
            }
            else {
                node.pathNodes = [[NSMutableArray alloc] init];
                MVAEdge *test = [[MVAEdge alloc] init];
                test.tripID = @"walking";
                node.pathEdges = [[NSMutableArray alloc] initWithObjects:test, nil];
                node.distance = infinity;
            }
        }
        
        MVAStop *stop = [[MVAStop alloc] init];
        stop.name = punInt.nombre;
        stop.latitude = punInt.coordinates.latitude;
        stop.longitude = punInt.coordinates.longitude;
        MVANode *node = [[MVANode alloc] init];
        node.distance = infinity;
        node.stop = stop;
        node.open = NO;
        node.identificador = (int)[self.nodes count];
        node.pathEdges = [[NSMutableArray alloc] init];
        node.pathNodes = [[NSMutableArray alloc] init];
        [alg.nodes addObject:node];
        MVAEdge *edge = [[MVAEdge alloc] init];
        edge.destini = node;
        edge.tripID = @"landmark";
        NSArray *keys = [destiniNodes allKeys];
        for (int i = 0; i < [keys count]; ++i) {
            NSNumber *key = [keys objectAtIndex:i];
            NSMutableArray *edges = [alg.edgeList objectAtIndex:[key intValue]];
            [edges addObject:edge];
            [alg.edgeList setObject:edges atIndexedSubscript:[key intValue]];
        }
        
        self.path = [alg dijkstraPathtoNode:node
                                    withCoo:punInt.coordinates];
    }
    else { // A*
        
        NSNumber *infinity = [NSNumber numberWithDouble:DBL_MAX];
        MVAAlgorithms *alg = [[MVAAlgorithms alloc] init];
        alg.viewController = self.viewController;
        alg.nodes = [self.nodes mutableCopy];
        alg.edgeList = self.edgeList;
        alg.type = self.type;
        alg.dataBus = self.dataBus;
        alg.dataFGC = self.dataFGC;
        alg.dataTMB = self.dataTMB;
        alg.openNodes = [[MVAPriorityQueue alloc] initWithCapacity:[self.nodes count]];
        alg.cal = self.cal;
        for (MVANode *node in self.nodes) {
            node.open = NO;
            node.pathEdges = [[NSMutableArray alloc] init];
            node.pathNodes = [[NSMutableArray alloc] init];
            if ([originNodes containsObject:[NSNumber numberWithInt:node.identificador]]) {
                double sec_rep = [self initTime];
                double dist = [self distanceForCoordinates:oCoords
                                            andCoordinates:CLLocationCoordinate2DMake(node.stop.latitude, node.stop.longitude)];
                double walkingSpeed = [self loadWalkingSpeed];
                sec_rep += ((dist * 1.2) / walkingSpeed);
                
                CLLocationCoordinate2D cordA = CLLocationCoordinate2DMake(node.stop.latitude, node.stop.longitude);
                node.previous = nil;
                
                if (self.type == 1) {
                    double next = sec_rep;
                    node.distance = [NSNumber numberWithDouble:(next)];
                    double dist = [self distanceForCoordinates:cordA andCoordinates:punInt.coordinates];
                    node.score = [NSNumber numberWithDouble:(next + (dist / [self loadWalkingSpeed]))];
                }
                else {
                    MVACalendar *cal = [self.dataTMB getCurrentCalendarforSubway:NO];
                    double freq = [self.dataBus frequencieForStop:node.stop andTime:sec_rep andCalendar:cal.serviceID];
                    node.distance = [NSNumber numberWithDouble:(sec_rep + freq)];
                    double dist = [self distanceForCoordinates:cordA andCoordinates:punInt.coordinates];
                    node.score = [NSNumber numberWithDouble:((sec_rep + freq) + (dist / [self loadWalkingSpeed]))];
                }
                MVAPair *p = [[MVAPair alloc] init];
                p.first = [node.score doubleValue];
                p.second = node.identificador;
                [alg.openNodes addObject:p];
                MVAEdge *test = [[MVAEdge alloc] init];
                test.tripID = @"walking";
                node.pathEdges = [[NSMutableArray alloc] initWithObjects:test, nil];
            }
            else {
                node.score = infinity;
                node.previous = nil;
                node.distance = infinity;
            }
        }
        
        MVAStop *stop = [[MVAStop alloc] init];
        stop.name = punInt.nombre;
        stop.latitude = punInt.coordinates.latitude;
        stop.longitude = punInt.coordinates.longitude;
        MVANode *node = [[MVANode alloc] init];
        node.distance = infinity;
        node.score = infinity;
        node.stop = stop;
        node.open = NO;
        node.identificador = (int)[self.nodes count];
        node.pathEdges = [[NSMutableArray alloc] init];
        node.pathNodes = [[NSMutableArray alloc] init];
        [alg.nodes addObject:node];
        MVAEdge *edge = [[MVAEdge alloc] init];
        edge.destini = node;
        edge.tripID = @"landmark";
        NSArray *keys = [destiniNodes allKeys];
        for (int i = 0; i < [keys count]; ++i) {
            NSNumber *key = [keys objectAtIndex:i];
            NSMutableArray *edges = [alg.edgeList objectAtIndex:[key intValue]];
            [edges addObject:edge];
            [alg.edgeList setObject:edges atIndexedSubscript:[key intValue]];
        }
        
        self.path = [alg astarPathtoNode:node
                                 withCoo:punInt.coordinates];
    }
    
    return self.path;
}

-(double)distanceForCoordinates:(CLLocationCoordinate2D)cordA andCoordinates:(CLLocationCoordinate2D)cordB
{
    double R = 6372797.560856;
    double dLat = ((cordB.latitude - cordA.latitude) * M_PI) / 180.0;
    double dLon = ((cordB.longitude - cordA.longitude) * M_PI) / 180.0;
    double lat1 = (cordA.latitude * M_PI) / 180.0;
    double lat2 = (cordB.latitude * M_PI) / 180.0;
    
    double a = (sin(dLat/2.0) * sin(dLat/2.0)) + (sin(dLon/2.0) * sin(dLon/2.0) * cos(lat1) * cos(lat2));
    double c = 2 * atan2(sqrt(a), sqrt(1-a));
    double realDist = (R * c);
    
    return (realDist * 1.2);
}

/**
 *  Encodes the receiver using a given archiver. (required)
 *
 *  @param coder An archiver object
 *
 *  @since version 1.0
 */
- (void)encodeWithCoder:(NSCoder *)coder;
{
    [coder encodeObject:self.nodes forKey:@"nodes"];
    [coder encodeObject:self.edgeList forKey:@"edges"];
    [coder encodeObject:[NSNumber numberWithInteger:self.type] forKey:@"type"];
}

/**
 *  Returns an object initialized from data in a given unarchiver. (required)
 *
 *  @param coder An unarchiver object
 *
 *  @return self, initialized using the data in decoder.
 *
 *  @since version 1.0
 */
- (id)initWithCoder:(NSCoder *)coder;
{
    self = [[MVAGraph alloc] init];
    if (self) {
        self.nodes = [coder decodeObjectForKey:@"nodes"];
        self.edgeList = [[coder decodeObjectForKey:@"edges"] mutableCopy];
        self.type = [[coder decodeObjectForKey:@"type"] intValue];
    }
    return self;
}

/**
 *  This function loads the walking speed indicated by the user. (The default value is 5km/h)
 *
 *  @return The speed in m/s
 *
 *  @since version 1.0
 */
-(double)loadWalkingSpeed
{
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.visitBCN.com"];
    NSString *nom = @"VisitBCNWalkingSpeed";
    NSData *data = [defaults objectForKey:nom];
    if(data == nil){
        [defaults setDouble:(5000.0/3600.0) forKey:nom];
        if ([self loadRain]) return ((5000.0/3600.0) / 1.2);
        return (5000.0/3600.0);
    }
    else {
        if ([self loadRain]) return ([defaults doubleForKey:nom] / 1.2);
        return [defaults doubleForKey:nom];
    }
}

/**
 *  This function loads the walking speed indicated by the user. (The default value is 5km/h)
 *
 *  @return The speed in m/s
 *
 *  @since version 1.0
 */
-(BOOL)loadRain
{
    int alg = 0;
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.visitBCN.com"];
    NSData *data = [defaults objectForKey:@"VisitBCNRain"];
    if(data == nil){
        [defaults setInteger:0 forKey:@"VisitBCNRain"];
    }
    else {
        alg = (int)[defaults integerForKey:@"VisitBCNRain"];
    }
    if (alg == 1) return YES;
    return NO;
}

/**
 *  This function calculates the initial time for this graph execution
 *
 *  @return The time in seconds
 *
 *  @since version 1.0
 */
-(double)initTime
{
    [NSTimeZone setDefaultTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Madrid"]];
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:[self loadCustomDate]];
    NSInteger hour = [components hour];
    NSInteger minute = [components minute];
    NSInteger seconds = [components second];
    double sec_rep = (hour * 3600) + (minute * 60) + seconds;
    return sec_rep;
}

/**
 *  This function loads if the user has selected a custom date
 *
 *  @return A boolean
 *
 *  @since version 1.0
 */
-(BOOL)customDate
{
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.visitBCN.com"];
    NSData *data = [defaults objectForKey:@"VisitBCNCustomDateEnabled"];
    if (data == nil) {
        [defaults setObject:@"NO" forKey:@"VisitBCNCustomDateEnabled"];
        return NO;
    }
    NSString *string = [defaults objectForKey:@"VisitBCNCustomDateEnabled"];
    if ([string isEqualToString:@"NO"]) return NO;
    return YES;
}

/**
 *  This function loads either the custom date chosen by the user or the current date of the device
 *
 *  @return An NSDate object
 *
 *  @since version 1.0
 */
-(NSDate *)loadCustomDate
{
    [NSTimeZone setDefaultTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Madrid"]];
    if (![self customDate]) return [NSDate date];
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.visitBCN.com"];
    NSDate *date = [defaults objectForKey:@"VisitBCNCustomDate"];
    if (!date) return [NSDate date];;
    return date;
}

@end