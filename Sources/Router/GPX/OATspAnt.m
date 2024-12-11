//
//  OATspAnt.m
//  OsmAnd
//
//  Created by Alexey Kulish on 20/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OATspAnt.h"
#import "OALog.h"

// Algorithm parameters:
// original amount of trail
static double c = 1.0;
// trail preference
static double alpha = 1;
// greedy preference
static double beta = 5;
// trail evaporation coefficient
static double evaporation = 0.5;
// new trail deposit coefficient;
static double Q = 500;
// number of ants used = numAntFactor*numTowns
static double numAntFactor = 0.8;
// probability of pure random selection of the next town
static double pr = 0.01;

// Reasonable number of iterations
// - results typically settle down by 500
static int maxIterations = 500;

// Ant class. Maintains tour and tabu information.
@interface OAAnt : NSObject

@property (nonatomic) NSMutableArray *tour;
// Maintain visited list for towns, much faster
// than checking if in tour so far.
@property (nonatomic) NSMutableArray *visited;

@end

@implementation OAAnt
{
    NSMutableArray *_graph;
    int *_currentIndex;
    int _n;
}


- (instancetype)initWithGraph:(NSMutableArray *)graph n:(int)n currentIndex:(int*)currentIndex
{
    self = [super init];
    if (self)
    {
        _graph = graph;
        
        self.tour = [OATspAnt createIntArray:n];
        self.visited = [OATspAnt createBoolArray:n];

        _n = n;
        _currentIndex = currentIndex;
    }
    return self;
}

- (void)visitTown:(int)town
{
    //OALog(@"town = %d", town);

    self.tour[*_currentIndex + 1] = [NSNumber numberWithInt:town];
    self.visited[town] = @YES;
}

- (BOOL)visited:(int)i
{
    return [self.visited[i] boolValue];
}
    
- (double)tourLength
{
    double length = [_graph[[self.tour[_n - 1] intValue]][[self.tour[0] intValue]] doubleValue];
    for (int i = 0; i < _n - 1; i++)
        length += [_graph[[self.tour[i] intValue]][[self.tour[i + 1] intValue]] doubleValue];

    return length;
}

- (void)clear
{
    for (int i = 0; i < _n; i++)
        self.visited[i] = @NO;
}

@end



@implementation OATspAnt
{
    int n; // # towns
    int m; // # ants
    NSMutableArray *graph;
    NSMutableArray *trails;
    NSMutableArray *ants;
    NSMutableArray *probs;

    int currentIndex;

    NSMutableArray *bestTour;
	double bestTourLength;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        n = 0;
        m = 0;
        currentIndex = 0;
    }
    return self;
}

+ (NSMutableArray *)createBoolArray:(NSInteger)length
{
    NSMutableArray *arr = [NSMutableArray array];
    for (int i = 0; i < length; i++)
        [arr addObject:@NO];
    
    return arr;
}

+ (NSMutableArray *)createIntArray:(NSInteger)length
{
    NSMutableArray *arr = [NSMutableArray array];
    for (int i = 0; i < length; i++)
        [arr addObject:@0];
    
    return arr;
}

+ (NSMutableArray *)createDoubleArray:(NSInteger)length
{
    NSMutableArray *arr = [NSMutableArray array];
    for (int i = 0; i < length; i++)
        [arr addObject:@0.0];
    
    return arr;
}

// Read in graph from a file.
// Allocates all memory.
// Adds 1 to edge lengths to ensure no zero length edges.
- (void)readGraph:(NSArray *)intermediates  start:(CLLocation *)start end:(CLLocation *)end
{
    NSMutableArray *l = [NSMutableArray array];
    [l addObject:start];
    [l addObjectsFromArray:intermediates];
    [l addObject:end];
    n = l.count;

    graph = [OATspAnt createDoubleArray:n];
    for (int i = 0; i < n; i++)
        graph[i] = [OATspAnt createDoubleArray:n];
    
    double maxSum = 0;
    for (int i = 0; i < n; i++)
    {
        double maxIWeight = 0;
        for (int j = 1; j < n; j++)
        {
            CLLocation *a = l[i];
            CLLocation *b = l[j];
            double d = rint([a distanceFromLocation:b]) + 0.1;
            maxIWeight = MAX(d, maxIWeight);
            graph[i][j] = [NSNumber numberWithDouble:d];
        }
        maxSum += maxIWeight;
    }
    maxSum = rint(maxSum) + 1;
    for (int i = 0; i < n; i++)
    {
        if (i == n - 1)
            graph[i][0] = @0.1;
        else
            graph[i][0] = [NSNumber numberWithDouble:maxSum];
    }
    
    m = (int) (n * numAntFactor);
    // all memory allocations done here
    trails = [OATspAnt createDoubleArray:n];
    for (int i = 0; i < n; i++)
        trails[i] = [OATspAnt createDoubleArray:n];

    probs = [OATspAnt createDoubleArray:n];
    ants = [NSMutableArray arrayWithCapacity:m];
    for (int j = 0; j < m; j++)
        [ants addObject:[[OAAnt alloc] initWithGraph:graph n:n currentIndex:&currentIndex]];
}

uint64_t doubleToBits(double x)
{
    const union { double f; uint64_t i; } xUnion = { .f = x };
    return xUnion.i;
}

double bitsToDouble(uint64_t bitPattern)
{
    double  doubleValue;
    doubleValue = *(double*)&bitPattern;
    return doubleValue;
}

// Approximate power function, Math.pow is quite slow and we don't need accuracy.
// See:
// https://martin.ankerl.com/2007/10/04/optimized-pow-approximation-for-java-and-c-c/
// Important facts:
// - >25 times faster
// - Extreme cases can lead to error of 25% - but usually less.
// - Does not harm results -- not surprising for a stochastic algorithm.
- (double)pow:(double)a b:(double)b
{
    //return pow(a, b);
    
    int x = (int) (doubleToBits(a) >> 32);
    int y = (int) (b * (x - 1072632447) + 1072632447);
    return bitsToDouble(((long long) y) << 32);
}

// Store in probs array the probability of moving to each town
// [1] describes how these are calculated.
// In short: ants like to follow stronger and shorter trails more.
- (void)probTo:(OAAnt *)ant
{
    int i = [((NSNumber *)ant.tour[currentIndex]) intValue];
    
    double denom = 0.0;
    for (int l = 0; l < n; l++)
        if (![ant visited:l])
            denom += [self pow:[((NSNumber *)trails[i][l]) doubleValue] b:alpha] * [self pow:1.0 / [((NSNumber *)graph[i][l]) doubleValue] b:beta];
    
    for (int j = 0; j < n; j++)
    {
        if ([ant visited:j])
        {
            probs[j] = @0.0;
        }
        else
        {
            double numerator = [self pow:[((NSNumber *)trails[i][j]) doubleValue] b:alpha] * [self pow:1.0 / [((NSNumber *)graph[i][j] ) doubleValue]b:beta];
            probs[j] = [NSNumber numberWithDouble:numerator / denom];
        }
    }
}

// Given an ant select the next town based on the probabilities
// we assign to each town. With pr probability chooses
// totally randomly (taking into account tabu list).
- (int)selectNextTown:(OAAnt *)ant
{
    // sometimes just randomly select
    if (arc4random_uniform(100000) / 100000.0 < pr)
    {
        int t = arc4random_uniform(n - currentIndex); // random town
        int j = -1;
        for (int i = 0; i < n; i++)
        {
            if (![ant visited:i])
                j++;
            if (j == t)
                return i;
        }
    }

    // calculate probabilities for each town (stored in probs)
    [self probTo:ant];
    
    // randomly select according to probs
    double r = arc4random_uniform(100000) / 100000.0;
    double tot = 0;
    for (int i = 0; i < n; i++)
    {
        tot += [((NSNumber *)probs[i]) doubleValue];
        if (tot >= r)
            return i;
    }
    
    assert("Not supposed to get here.");
    return -1;
}

// Update trails based on ants tours
- (void)updateTrails
{
    // evaporation
    for (int i = 0; i < n; i++)
        for (int j = 0; j < n; j++)
        {
            NSNumber *num = trails[i][j];
            trails[i][j] = [NSNumber numberWithDouble:[num doubleValue] * evaporation];
        }
    
    // each ants contribution
    for (OAAnt *a in ants)
    {
        double contribution = Q / [a tourLength];
        for (int i = 0; i < n - 1; i++)
        {
            int x = [a.tour[i] intValue];
            int y = [a.tour[i + 1] intValue];
            NSNumber *num = trails[x][y];
            trails[x][y] = [NSNumber numberWithDouble:[num doubleValue] + contribution];
        }

        int x = [a.tour[n - 1] intValue];
        int y = [a.tour[0] intValue];
        NSNumber *num = trails[x][y];
        trails[x][y] = [NSNumber numberWithDouble:[num doubleValue] + contribution];
    }
}

// Choose the next town for all ants
- (void)moveAnts
{
    // each ant follows trails...
    while (currentIndex < n - 1)
    {
        for (OAAnt *a in ants)
            [a visitTown:[self selectNextTown:a]];
        
        currentIndex++;
    }
}

// m ants with random start city
- (void)setupAnts
{
    currentIndex = -1;
    for (int i = 0; i < m; i++)
    {
        OAAnt *a = ants[i];
        [a clear]; // faster than fresh allocations.
        [a visitTown:arc4random_uniform(n)];
    }
    currentIndex++;
}

- (void)updateBest
{
    if (bestTour == nil)
    {
        bestTour = ((OAAnt *)ants[0]).tour;
        bestTourLength = [((OAAnt *)ants[0]) tourLength];
    }
    for (OAAnt *a in ants)
    {
        if ([a tourLength] < bestTourLength)
        {
            bestTourLength = [a tourLength];
            bestTour = [a.tour mutableCopy];
        }
    }
}

- (NSString *)tourToString:(NSMutableArray *)tour
{
    NSMutableString *t = [NSMutableString string];
    for (NSNumber *i in tour)
    {
        [t appendString:@" "];
        [t appendFormat:@"%d", [i intValue]];
    }
    return t;
}

- (NSArray *)solve
{
    // clear trails
    for (int i = 0; i < n; i++)
        for (int j = 0; j < n; j++)
            trails[i][j] = [NSNumber numberWithDouble:c];
    
    int iteration = 0;
    // run for maxIterations
    // preserve best tour
    while (iteration < maxIterations)
    {
        [self setupAnts];
        [self moveAnts];
        [self updateTrails];
        [self updateBest];
        iteration++;
    }
    // Subtract n because we added one to edges on load
    OALog(@"Best tour length: %f", bestTourLength - n * 0.1);
    OALog(@"Best tour: %@", [self tourToString:bestTour]);
    return [self alignAnswer:[bestTour copy]];
}

- (NSArray *)alignAnswer:(NSArray *)ans
{
    NSMutableArray *alignAns = [OATspAnt createIntArray:ans.count];
    int shift = 0;
    for(int j = 0; j < ans.count; j++)
    {
        if([((NSNumber *)ans[j]) intValue] == 0)
        {
            shift = j;
            break;
        }
    }
    for (int j = 0; j < ans.count; j++)
    {
        alignAns[(j - shift + ans.count) % ans.count] = ans[j];
    }
    return alignAns;
}

- (void)test
{
    NSMutableArray *l = [NSMutableArray array];
    CLLocation *start = [[CLLocation alloc] initWithLatitude:52.2956 longitude:4.95];
    CLLocation *farest = [[CLLocation alloc] initWithLatitude:52.4556 longitude:4.6739];
    
    [l addObject:[[CLLocation alloc] initWithLatitude:52.33 longitude:4.67]]; // 2.
    [l addObject:[[CLLocation alloc] initWithLatitude:52.4556 longitude:4.6739]]; // 3.
    [l addObject:[[CLLocation alloc] initWithLatitude:52.59 longitude:4.671]]; // 4.
    [l addObject:[[CLLocation alloc] initWithLatitude:52.608 longitude:4.9005]]; // 5.
    [l addObject:[[CLLocation alloc] initWithLatitude:52.56 longitude:4.9505]]; // 6.
    [l addObject:[[CLLocation alloc] initWithLatitude:52.49 longitude:4.9705]]; // 7.
    [l addObject:[[CLLocation alloc] initWithLatitude:52.35 longitude:4.9405]]; // 8.
    
    // shuffle array
    NSMutableArray *sh = [NSMutableArray arrayWithArray:l];
    for (int x = 0; x < sh.count; x++)
    {
        int randInt = (arc4random() % (sh.count - x)) + x;
        [sh exchangeObjectAtIndex:x withObjectAtIndex:randInt];
    }
    
    int mixedOrder[l.count];
    NSMutableString *mixStr = [NSMutableString string];
    [mixStr appendString:@"["];
    for (int i = 0; i < sh.count; i++)
    {
        for (int j = 0; j < l.count; j++)
        {
            if (l[j] == sh[i])
            {
                mixedOrder[i] = j;
                [mixStr appendFormat:@"%d", j];
                [mixStr appendString:@", "];
                break;
            }
        }
    }
    [mixStr appendString:@"]"];
    
    OALog(@"%@", mixStr);
    
    //		ans = new TspHeldKarp().readInput(sh, true).solve();
    CLLocation *end = farest;
    OATspAnt *t = [[OATspAnt alloc] init];
    [t readGraph:sh start:start end:end];
    NSArray *ans = [t solve];
    
    double s = 0;
    int order[ans.count];
    double dist[ans.count];
    order[0] = 0;
    for (int k = 1; k < ans.count; k++)
    {
        int ansK = [((NSNumber *)ans[k]) intValue];
        int ansKp = [((NSNumber *)ans[k - 1]) intValue];
        
        if(k == ans.count - 1)
        {
            int p = mixedOrder[ansKp - 1];
            dist[k] = [end distanceFromLocation:l[p]];
            order[k] = ansK;
        }
        else
        {
            int c = mixedOrder[ansK - 1];
            order[k] = c + 1;
            if (k == 1)
            {
                dist[k] = [start distanceFromLocation:l[c]];
            }
            else
            {
                int p = mixedOrder[ansKp - 1];
                dist[k] = [((CLLocation *)l[p]) distanceFromLocation:l[c]];
            }
        }
        s += dist[k];
    }
    
    NSMutableString *log = [NSMutableString string];
    [log appendString:@"Result order: "];
    for (int i = 0; i < ans.count; i++)
        [log appendFormat:@"%d ", order[i]];
    
    OALog(@"%@", log);
    
    log = [NSMutableString string];
    [log appendString:@"Result dist: "];
    for (int i = 1; i < ans.count - 1; i++)
        [log appendFormat:@"%f ", dist[i]];
    
    OALog(@"%@", log);
}

@end
