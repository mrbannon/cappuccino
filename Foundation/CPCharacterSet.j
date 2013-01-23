/*
 * CPCharacterSet.j
 * Foundation
 *
 * Copyright 2008, Emanuele Vulcano
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import "CPArray.j"
@import "CPException.j"
@import "CPObject.j"
@import "CPString.j"
@import "CPURL.j"

// CPCharacterSet is a class cluster. Concrete implementations
// follow after the main abstract class.

var _builtInCharacterSets = {};

@implementation CPCharacterSet : CPObject
{
    BOOL _inverted;
}

// Missing methods
/*
- (BOOL)isSupersetOfSet:(CPCharacterSet)theOtherSet{}
+ (id)characterSetWithBitmapRepresentation:(CPData)data{}
+ (id)characterSetWithContentsOfFile:(CPString)path{}
- (CPData)bitmapRepresentation{}

- (void)formIntersectionWithCharacterSet:(CPCharacterSet)otherSet
- (void)formUnionWithCharacterSet:(CPCharacterSet)otherSet
- (void)removeCharactersInRange:(CPRange)aRange
- (void)removeCharactersInString:(CPString)aString
*/

- (id)init
{
    self = [super init];

    if (self)
        _inverted = NO;

    return self;
}

- (void)invert
{
    _inverted = !_inverted;
}

- (BOOL)characterIsMember:(CPString)aCharacter
{
    // IMPLEMENTED BY SUBCLASSES
}

- (BOOL)hasMemberInPlane:(int)aPlane
{
    // IMPLEMENTED BY SUBCLASSES
}

+ (id)characterSetWithCharactersInString:(CPString)aString
{
    return [[_CPStringContentCharacterSet alloc] initWithString:aString];
}

+ (id)characterSetWithRange:(CPRange)aRange
{
    return [[_CPRangeCharacterSet alloc] initWithRange:aRange];
}

+ (id)alphanumericCharacterSet
{
    return [CPCharacterSet _sharedCharacterSetWithName:_cmd];
}

+ (id)controlCharacterSet
{
    return [CPCharacterSet _sharedCharacterSetWithName:_cmd];
}

+ (id)decimalDigitCharacterSet
{
    return [CPCharacterSet _sharedCharacterSetWithName:_cmd];
}

+ (id)decomposableCharacterSet
{
    return [CPCharacterSet _sharedCharacterSetWithName:_cmd];
}

+ (id)illegalCharacterSet
{
    return [CPCharacterSet _sharedCharacterSetWithName:_cmd];
}

+ (id)letterCharacterSet
{
    return [CPCharacterSet _sharedCharacterSetWithName:_cmd];
}

+ (id)lowercaseLetterCharacterSet
{
    return [CPCharacterSet _sharedCharacterSetWithName:_cmd];
}

+ (id)nonBaseCharacterSet
{
    return [CPCharacterSet _sharedCharacterSetWithName:_cmd];
}

+ (id)punctuationCharacterSet
{
    return [CPCharacterSet _sharedCharacterSetWithName:_cmd];
}

+ (id)uppercaseLetterCharacterSet
{
    return [CPCharacterSet _sharedCharacterSetWithName:_cmd];
}

+ (id)whitespaceAndNewlineCharacterSet
{
    return [CPCharacterSet _sharedCharacterSetWithName:_cmd];
}

+ (id)whitespaceCharacterSet
{
    return [CPCharacterSet _sharedCharacterSetWithName:_cmd];
}

// private methods
+ (id)_sharedCharacterSetWithName:(id)csname
{
    var cs = _builtInCharacterSets[csname];

    if (!cs)
    {
        var i = 0,
            ranges = [CPArray array],
            rangeArray = eval(csname);

        for (; i < rangeArray.length; i+= 2)
        {
            var loc = rangeArray[i],
                length = rangeArray[i + 1],
                range = CPMakeRange(loc,length);
            [ranges addObject:range];
        }

        cs = [[_CPRangeCharacterSet alloc] initWithRanges:ranges];
        _builtInCharacterSets[csname] = cs;
    }

    return cs;
}

- (void)_setInverted:flag
{
    _inverted = flag;
}

@end

var CPCharacterSetInvertedKey = @"CPCharacterSetInvertedKey";

@implementation CPCharacterSet (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super init])
    {
        _inverted = [aCoder decodeBoolForKey:CPCharacterSetInvertedKey];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeBool:_inverted forKey:CPCharacterSetInvertedKey];
}

@end

// A character set that stores a list of ranges of
// acceptable characters.
@implementation _CPRangeCharacterSet : CPCharacterSet
{
    CPArray _ranges;
}

// Creates a range character set with a single range.
- (id)initWithRange:(CPRange)r
{
    return [self initWithRanges:[CPArray arrayWithObject:r]];
}

// Creates a range character set with multiple ranges.
- (id)initWithRanges:(CPArray)ranges
{
    self = [super init];

    if (self)
    {
        _ranges = ranges;
    }

    return self;
}

- (id)copy
{
    var set = [[_CPRangeCharacterSet alloc] initWithRanges:_ranges];
    [set _setInverted:_inverted];
    return set;
}

- (id)invertedSet
{
    var set = [[_CPRangeCharacterSet alloc] initWithRanges:_ranges];
    [set invert];
    return set;
}

- (BOOL)characterIsMember:(CPString)aCharacter
{
    var c = aCharacter.charCodeAt(0),
        enu = [_ranges objectEnumerator],
        range;

    while ((range = [enu nextObject]) !== nil)
    {
        if (CPLocationInRange(c, range))
            return !_inverted;
    }

    return _inverted;
}

- (BOOL)hasMemberInPlane:(int)plane // TO DO : when inverted
{
    // JavaScript strings can only return char codes
    // up to 0xFFFF (per the ECMA standard), so
    // they all live in the Basic Multilingual Plane
    // (aka plane 0).

    if (plane !== 0)
        return NO;

    var enu = [_ranges objectEnumerator],
        range;

    while ((range = [enu nextObject]) !== nil)
    {
        if (!CPEmptyRange(range))
            return YES;
    }

    return NO;
}

- (void)addCharactersInRange:(CPRange)aRange // Needs _inverted support
{
    [_ranges addObject:aRange];
}

- (void)addCharactersInString:(CPString)aString // Needs _inverted support
{
    var i = 0;

    for (; i < aString.length; i++)
    {
        var code = aString.charCodeAt(i),
            range = CPMakeRange(code,1);

        [_ranges addObject:range];
    }
}

@end

// A character set that scans a string's contents for
// acceptable characters.
@implementation _CPStringContentCharacterSet : CPCharacterSet
{
    CPString _string;
}

- (id)initWithString:(CPString)s
{
    self = [super init];

    if (self)
    {
        _string = s;
    }

    return self;
}

- (id)copy
{
    var set = [[_CPStringContentCharacterSet alloc] initWithString:_string];
    [set _setInverted:_inverted];

    return set;
}

- (id)invertedSet
{
    var set = [[_CPStringContentCharacterSet alloc] initWithString:_string];
    [set invert];

    return set;
}

- (BOOL)characterIsMember:(CPString)c
{
    return (_string.indexOf(c.charAt(0)) !== -1) === !_inverted;
}

- (CPString)description
{
    return [super description] + " { string = '" + _string + "'}";
}

- (BOOL)hasMemberInPlane:(int)plane
{
    // JavaScript strings can only return char codes
    // up to 0xFFFF (per the ECMA standard), so
    // they all live in the Basic Multilingual Plane
    // (aka plane 0).

    return _string.length && plane === 0;
}

- (void)addCharactersInRange:(CPRange)aRange // Needs _inverted support
{
    var i = aRange.location,
        count = aRange.location + aRange.length;

    for (; i < count; i++)
    {
        var s = String.fromCharCode(i);

        if (![self characterIsMember:s])
            _string = [_string stringByAppendingString:s];
    }
}

- (void)addCharactersInString:(CPString)aString // Needs _inverted support
{
    var i = 0;

    for (; i < aString.length; i++)
    {
        var s = aString.charAt(i);

        if (![self characterIsMember:s])
            _string = [_string stringByAppendingString:s];
    }
}

- (BOOL)isEqual:(CPCharacterSet)aCharacterSet
{
    if (self === aCharacterSet)
        return YES;

    if (!aCharacterSet || ![aCharacterSet isKindOfClass:[self class]])
        return NO;

    return [self _isEqualToStringContentCharacterSet:aCharacterSet];
}

- (BOOL)_isEqualToStringContentCharacterSet:(_CPStringContentCharacterSet)aCharacterSet
{
    if (!aCharacterSet)
        return NO;

    return _string === aCharacterSet._string && _inverted === aCharacterSet._inverted;
}

@end

var _CPStringContentCharacterSetStringKey = @"_CPStringContentCharacterSetStringKey";

@implementation _CPStringContentCharacterSet (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        _string = [aCoder decodeObjectForKey:_CPStringContentCharacterSetStringKey]
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_string forKey:_CPStringContentCharacterSetStringKey];
}

@end

_CPCharacterSetTrimAtBeginning  = 1 << 1;
_CPCharacterSetTrimAtEnd        = 1 << 2;

@implementation CPString (CPCharacterSetAdditions)

/*!
    Tokenizes the receiver string using the characters
    in a given set. For example, if the receiver is:
    \c "Baku baku to jest  skład."
    and the set is [CPCharacterSet whitespaceCharacterSet]
    the returned array would contain:
    <pre> ["Baku", "baku", "to", "jest", "", "skład."] </pre>
    Adjacent occurrences of the separator characters produce empty strings in the result.
    @author Arkadiusz Młynarczyk <arek@tupux.com>
    @param A character set containing the characters to use to split the receiver. Must not be nil.
    @return An CPArray object containing substrings from the receiver that have been divided by characters in separator.
*/
- (CPArray)componentsSeparatedByCharactersInSet:(CPCharacterSet)separator
{
    if (!separator)
        [CPException raise:CPInvalidArgumentException
                    reason:"componentsSeparatedByCharactersInSet: the separator can't be 'nil'"];

    var components = [CPMutableArray array],
        componentRange = CPMakeRange(0, 0),
        i = 0;

    for (; i < self.length; i++)
    {
        if ([separator characterIsMember:self.charAt(i)])
        {
            componentRange.length = i - componentRange.location;
            [components addObject:[self substringWithRange:componentRange]];
            componentRange.location += componentRange.length + 1;
        }
    }

    componentRange.length = self.length - componentRange.location;
    [components addObject:[self substringWithRange:componentRange]];

    return components;
}

// As per the Cocoa method.
- (id)stringByTrimmingCharactersInSet:(CPCharacterSet)set
{
    return [self _stringByTrimmingCharactersInSet:set options:_CPCharacterSetTrimAtBeginning | _CPCharacterSetTrimAtEnd];
}

// private method evilness!
// CPScanner's scanUpToString:... methods rely on this
// method being present.
- (id)_stringByTrimmingCharactersInSet:(CPCharacterSet)set options:(int)options
{
    var str = self;

    if (options & _CPCharacterSetTrimAtBeginning)
    {
        var cutEdgeBeginning = 0;

        while (cutEdgeBeginning < self.length && [set characterIsMember:self.charAt(cutEdgeBeginning)])
            cutEdgeBeginning++;

        str = str.substr(cutEdgeBeginning);
    }

    if (options & _CPCharacterSetTrimAtEnd)
    {
        var cutEdgeEnd = str.length;

        while (cutEdgeEnd > 0 && [set characterIsMember:self.charAt(cutEdgeEnd)])
            cutEdgeEnd--;

        str = str.substr(0, cutEdgeEnd + 1);
    }

    return str;
}

@end

alphanumericCharacterSet = [
48,10,
65,26,
97,26,
170,1,
178,2,
181,1,
185,2,
188,3,
192,23,
216,31,
248,458,
710,12,
736,5,
750,1,
768,112,
890,4,
902,1,
904,3,
908,1,
910,20,
931,44,
976,38,
1015,139,
1155,4,
1160,140,
1329,38,
1369,1,
1377,39,
1425,45,
1471,1,
1473,2,
1476,2,
1479,1,
1488,27,
1520,3,
1552,6,
1569,26,
1600,31,
1632,10,
1646,102,
1749,8,
1758,11,
1770,19,
1791,1,
1808,59,
1869,33,
1920,50,
1984,54,
2042,1,
2305,57,
2364,18,
2384,5,
2392,12,
2406,10,
2427,5,
2433,3,
2437,8,
2447,2,
2451,22,
2474,7,
2482,1,
2486,4,
2492,9,
2503,2,
2507,4,
2519,1,
2524,2,
2527,5,
2534,12,
2548,6,
2561,3,
2565,6,
2575,2,
2579,22,
2602,7,
2610,2,
2613,2,
2616,2,
2620,1,
2622,5,
2631,2,
2635,3,
2649,4,
2654,1,
2662,15,
2689,3,
2693,9,
2703,3,
2707,22,
2730,7,
2738,2,
2741,5,
2748,10,
2759,3,
2763,3,
2768,1,
2784,4,
2790,10,
2817,3,
2821,8,
2831,2,
2835,22,
2858,7,
2866,2,
2869,5,
2876,8,
2887,2,
2891,3,
2902,2,
2908,2,
2911,3,
2918,10,
2929,1,
2946,2,
2949,6,
2958,3,
2962,4,
2969,2,
2972,1,
2974,2,
2979,2,
2984,3,
2990,12,
3006,5,
3014,3,
3018,4,
3031,1,
3046,13,
3073,3,
3077,8,
3086,3,
3090,23,
3114,10,
3125,5,
3134,7,
3142,3,
3146,4,
3157,2,
3168,2,
3174,10,
3202,2,
3205,8,
3214,3,
3218,23,
3242,10,
3253,5,
3260,9,
3270,3,
3274,4,
3285,2,
3294,1,
3296,4,
3302,10,
3330,2,
3333,8,
3342,3,
3346,23,
3370,16,
3390,6,
3398,3,
3402,4,
3415,1,
3424,2,
3430,10,
3458,2,
3461,18,
3482,24,
3507,9,
3517,1,
3520,7,
3530,1,
3535,6,
3542,1,
3544,8,
3570,2,
3585,58,
3648,15,
3664,10,
3713,2,
3716,1,
3719,2,
3722,1,
3725,1,
3732,4,
3737,7,
3745,3,
3749,1,
3751,1,
3754,2,
3757,13,
3771,3,
3776,5,
3782,1,
3784,6,
3792,10,
3804,2,
3840,1,
3864,2,
3872,20,
3893,1,
3895,1,
3897,1,
3902,10,
3913,34,
3953,20,
3974,6,
3984,8,
3993,36,
4038,1,
4096,34,
4131,5,
4137,2,
4140,7,
4150,4,
4160,10,
4176,10,
4256,38,
4304,43,
4348,1,
4352,90,
4447,68,
4520,82,
4608,73,
4682,4,
4688,7,
4696,1,
4698,4,
4704,41,
4746,4,
4752,33,
4786,4,
4792,7,
4800,1,
4802,4,
4808,15,
4824,57,
4882,4,
4888,67,
4959,1,
4969,20,
4992,16,
5024,85,
5121,620,
5743,8,
5761,26,
5792,75,
5870,3,
5888,13,
5902,7,
5920,21,
5952,20,
5984,13,
5998,3,
6002,2,
6016,52,
6070,30,
6103,1,
6108,2,
6112,10,
6128,10,
6155,3,
6160,10,
6176,88,
6272,42,
6400,29,
6432,12,
6448,12,
6470,40,
6512,5,
6528,42,
6576,26,
6608,10,
6656,28,
6912,76,
6992,10,
7019,9,
7424,203,
7678,158,
7840,90,
7936,22,
7960,6,
7968,38,
8008,6,
8016,8,
8025,1,
8027,1,
8029,1,
8031,31,
8064,53,
8118,7,
8126,1,
8130,3,
8134,7,
8144,4,
8150,6,
8160,13,
8178,3,
8182,7,
8304,2,
8308,6,
8319,11,
8336,5,
8400,32,
8450,1,
8455,1,
8458,10,
8469,1,
8473,5,
8484,1,
8486,1,
8488,1,
8490,4,
8495,11,
8508,4,
8517,5,
8526,1,
8531,50,
9312,60,
9450,22,
10102,30,
11264,47,
11312,47,
11360,13,
11380,4,
11392,101,
11517,1,
11520,38,
11568,54,
11631,1,
11648,23,
11680,7,
11688,7,
11696,7,
11704,7,
11712,7,
11720,7,
11728,7,
11736,7,
12293,3,
12321,15,
12337,5,
12344,5,
12353,86,
12441,2,
12445,3,
12449,90,
12540,4,
12549,40,
12593,94,
12690,4,
12704,24,
12784,16,
12832,10,
12881,15,
12928,10,
12977,15,
13312,6582,
19968,20924,
40960,1165,
42775,4,
43008,40,
43072,52,
44032,11172,
63744,302,
64048,59,
64112,106,
64256,7,
64275,5,
64285,12,
64298,13,
64312,5,
64318,1,
64320,2,
64323,2,
64326,108,
64467,363,
64848,64,
64914,54,
65008,12,
65024,16,
65056,4,
65136,5,
65142,135,
65296,10,
65313,26,
65345,26,
65382,89,
65474,6,
65482,6,
65490,6
];

controlCharacterSet = [
0,32,
127,33,
173,1,
1536,4,
1757,1,
1807,1,
6068,2,
8203,5,
8234,5,
8288,4,
8298,6,
65279,1
];

decimalDigitCharacterSet = [
48,10,
1632,10,
1776,10,
1984,10,
2406,10,
2534,10,
2662,10,
2790,10,
2918,10,
3046,10,
3174,10,
3302,10,
3430,10,
3664,10,
3792,10,
3872,10,
4160,10,
6112,10,
6160,10,
6470,10,
6608,10,
6992,10
];

decomposableCharacterSet = [
192,6,
199,9,
209,6,
217,5,
224,6,
231,9,
241,6,
249,5,
255,17,
274,20,
296,9,
308,4,
313,6,
323,6,
332,6,
340,18,
360,23,
416,2,
431,2,
461,16,
478,6,
486,11,
500,2,
504,36,
542,2,
550,14,
832,2,
835,2,
884,1,
894,1,
901,6,
908,1,
910,3,
938,7,
970,5,
979,2,
1024,2,
1027,1,
1031,1,
1036,3,
1049,1,
1081,1,
1104,2,
1107,1,
1111,1,
1116,3,
1142,2,
1217,2,
1232,4,
1238,2,
1242,6,
1250,6,
1258,12,
1272,2,
1570,5,
1728,1,
1730,1,
1747,1,
2345,1,
2353,1,
2356,1,
2392,8,
2507,2,
2524,2,
2527,1,
2611,1,
2614,1,
2649,3,
2654,1,
2888,1,
2891,2,
2908,2,
2964,1,
3018,3,
3144,1,
3264,1,
3271,2,
3274,2,
3402,3,
3546,1,
3548,3,
3907,1,
3917,1,
3922,1,
3927,1,
3932,1,
3945,1,
3955,1,
3957,2,
3960,1,
3969,1,
3987,1,
3997,1,
4002,1,
4007,1,
4012,1,
4025,1,
4134,1,
6918,1,
6920,1,
6922,1,
6924,1,
6926,1,
6930,1,
6971,1,
6973,1,
6976,2,
6979,1,
7680,154,
7835,1,
7840,90,
7936,22,
7960,6,
7968,38,
8008,6,
8016,8,
8025,1,
8027,1,
8029,1,
8031,31,
8064,53,
8118,7,
8126,1,
8129,4,
8134,14,
8150,6,
8157,19,
8178,3,
8182,8,
8192,2,
8486,1,
8490,2,
8602,2,
8622,1,
8653,3,
8708,1,
8713,1,
8716,1,
8740,1,
8742,1,
8769,1,
8772,1,
8775,1,
8777,1,
8800,1,
8802,1,
8813,5,
8820,2,
8824,2,
8832,2,
8836,2,
8840,2,
8876,4,
8928,4,
8938,4,
9001,2,
10972,1,
12364,1,
12366,1,
12368,1,
12370,1,
12372,1,
12374,1,
12376,1,
12378,1,
12380,1,
12382,1,
12384,1,
12386,1,
12389,1,
12391,1,
12393,1,
12400,2,
12403,2,
12406,2,
12409,2,
12412,2,
12436,1,
12446,1,
12460,1,
12462,1,
12464,1,
12466,1,
12468,1,
12470,1,
12472,1,
12474,1,
12476,1,
12478,1,
12480,1,
12482,1,
12485,1,
12487,1,
12489,1,
12496,2,
12499,2,
12502,2,
12505,2,
12508,2,
12532,1,
12535,4,
12542,1,
44032,11172,
63744,270,
64016,1,
64018,1,
64021,10,
64032,1,
64034,1,
64037,2,
64042,4,
64048,59,
64112,106,
64285,1,
64287,1,
64298,13,
64312,5,
64318,1,
64320,2,
64323,2
];

illegalCharacterSet = [
880,4,
886,4,
895,5,
907,1,
909,1,
930,1,
975,1,
1159,1,
1300,29,
1367,2,
1376,1,
1416,1,
1419,6,
1480,8,
1515,5,
1525,11,
1540,7,
1558,5,
1564,2,
1568,1,
1595,5,
1631,1,
1806,1,
1867,2,
1902,18,
1970,14,
2043,262,
2362,2,
2382,2,
2389,3,
2417,10,
2432,1,
2436,1,
2445,2,
2449,2,
2473,1,
2481,1,
2483,3,
2490,2,
2501,2,
2505,2,
2511,8,
2520,4,
2526,1,
2532,2,
2555,6,
2564,1,
2571,4,
2577,2,
2601,1,
2609,1,
2612,1,
2615,1,
2618,2,
2621,1,
2627,4,
2633,2,
2638,11,
2653,1,
2655,7,
2677,12,
2692,1,
2702,1,
2706,1,
2729,1,
2737,1,
2740,1,
2746,2,
2758,1,
2762,1,
2766,2,
2769,15,
2788,2,
2800,1,
2802,15,
2820,1,
2829,2,
2833,2,
2857,1,
2865,1,
2868,1,
2874,2,
2884,3,
2889,2,
2894,8,
2904,4,
2910,1,
2914,4,
2930,16,
2948,1,
2955,3,
2961,1,
2966,3,
2971,1,
2973,1,
2976,3,
2981,3,
2987,3,
3002,4,
3011,3,
3017,1,
3022,9,
3032,14,
3067,6,
3076,1,
3085,1,
3089,1,
3113,1,
3124,1,
3130,4,
3141,1,
3145,1,
3150,7,
3159,9,
3170,4,
3184,18,
3204,1,
3213,1,
3217,1,
3241,1,
3252,1,
3258,2,
3269,1,
3273,1,
3278,7,
3287,7,
3295,1,
3300,2,
3312,1,
3315,15,
3332,1,
3341,1,
3345,1,
3369,1,
3386,4,
3396,2,
3401,1,
3406,9,
3416,8,
3426,4,
3440,18,
3460,1,
3479,3,
3506,1,
3516,1,
3518,2,
3527,3,
3531,4,
3541,1,
3543,1,
3552,18,
3573,12,
3643,4,
3676,37,
3715,1,
3717,2,
3721,1,
3723,2,
3726,6,
3736,1,
3744,1,
3748,1,
3750,1,
3752,2,
3756,1,
3770,1,
3774,2,
3781,1,
3783,1,
3790,2,
3802,2,
3806,34,
3912,1,
3947,6,
3980,4,
3992,1,
4029,1,
4045,2,
4050,46,
4130,1,
4136,1,
4139,1,
4147,3,
4154,6,
4186,70,
4294,10,
4349,3,
4442,5,
4515,5,
4602,6,
4681,1,
4686,2,
4695,1,
4697,1,
4702,2,
4745,1,
4750,2,
4785,1,
4790,2,
4799,1,
4801,1,
4806,2,
4823,1,
4881,1,
4886,2,
4955,4,
4989,3,
5018,6,
5109,12,
5751,9,
5789,3,
5873,15,
5901,1,
5909,11,
5943,9,
5972,12,
5997,1,
6001,1,
6004,12,
6110,2,
6122,6,
6138,6,
6159,1,
6170,6,
6264,8,
6314,86,
6429,3,
6444,4,
6460,4,
6465,3,
6510,2,
6517,11,
6570,6,
6602,6,
6618,4,
6684,2,
6688,224,
6988,4,
7037,387,
7627,51,
7836,4,
7930,6,
7958,2,
7966,2,
8006,2,
8014,2,
8024,1,
8026,1,
8028,1,
8030,1,
8062,2,
8117,1,
8133,1,
8148,2,
8156,1,
8176,2,
8181,1,
8191,1,
8292,6,
8306,2,
8335,1,
8341,11,
8374,26,
8432,16,
8527,4,
8581,11,
9192,24,
9255,25,
9291,21,
9885,3,
9907,78,
9989,1,
9994,2,
10024,1,
10060,1,
10062,1,
10067,3,
10071,1,
10079,2,
10133,3,
10160,1,
10175,1,
10187,5,
10220,4,
11035,5,
11044,220,
11311,1,
11359,1,
11373,7,
11384,8,
11499,14,
11558,10,
11622,9,
11632,16,
11671,9,
11687,1,
11695,1,
11703,1,
11711,1,
11719,1,
11727,1,
11735,1,
11743,33,
11800,4,
11806,98,
11930,1,
12020,12,
12246,26,
12284,4,
12352,1,
12439,2,
12544,5,
12589,4,
12687,1,
12728,8,
12752,32,
12831,1,
12868,12,
13055,1,
19894,10,
40892,68,
42125,3,
42183,569,
42779,5,
42786,222,
43052,20,
43128,904,
55204,92,
64046,2,
64107,5,
64218,38,
64263,12,
64280,5,
64311,1,
64317,1,
64319,1,
64322,1,
64325,1,
64434,33,
64832,16,
64912,2,
64968,40,
65022,2,
65050,6,
65060,12,
65107,1,
65127,1,
65132,4,
65141,1,
65277,2,
65280,1,
65471,3,
65480,2,
65488,2,
65496,2,
65501,3,
65511,1,
65519,10
];

letterCharacterSet = [
65,26,
97,26,
170,1,
181,1,
186,1,
192,23,
216,31,
248,458,
710,12,
736,5,
750,1,
768,112,
890,4,
902,1,
904,3,
908,1,
910,20,
931,44,
976,38,
1015,139,
1155,4,
1160,140,
1329,38,
1369,1,
1377,39,
1425,45,
1471,1,
1473,2,
1476,2,
1479,1,
1488,27,
1520,3,
1552,6,
1569,26,
1600,31,
1646,102,
1749,8,
1758,11,
1770,6,
1786,3,
1791,1,
1808,59,
1869,33,
1920,50,
1994,44,
2042,1,
2305,57,
2364,18,
2384,5,
2392,12,
2427,5,
2433,3,
2437,8,
2447,2,
2451,22,
2474,7,
2482,1,
2486,4,
2492,9,
2503,2,
2507,4,
2519,1,
2524,2,
2527,5,
2544,2,
2561,3,
2565,6,
2575,2,
2579,22,
2602,7,
2610,2,
2613,2,
2616,2,
2620,1,
2622,5,
2631,2,
2635,3,
2649,4,
2654,1,
2672,5,
2689,3,
2693,9,
2703,3,
2707,22,
2730,7,
2738,2,
2741,5,
2748,10,
2759,3,
2763,3,
2768,1,
2784,4,
2817,3,
2821,8,
2831,2,
2835,22,
2858,7,
2866,2,
2869,5,
2876,8,
2887,2,
2891,3,
2902,2,
2908,2,
2911,3,
2929,1,
2946,2,
2949,6,
2958,3,
2962,4,
2969,2,
2972,1,
2974,2,
2979,2,
2984,3,
2990,12,
3006,5,
3014,3,
3018,4,
3031,1,
3073,3,
3077,8,
3086,3,
3090,23,
3114,10,
3125,5,
3134,7,
3142,3,
3146,4,
3157,2,
3168,2,
3202,2,
3205,8,
3214,3,
3218,23,
3242,10,
3253,5,
3260,9,
3270,3,
3274,4,
3285,2,
3294,1,
3296,4,
3330,2,
3333,8,
3342,3,
3346,23,
3370,16,
3390,6,
3398,3,
3402,4,
3415,1,
3424,2,
3458,2,
3461,18,
3482,24,
3507,9,
3517,1,
3520,7,
3530,1,
3535,6,
3542,1,
3544,8,
3570,2,
3585,58,
3648,15,
3713,2,
3716,1,
3719,2,
3722,1,
3725,1,
3732,4,
3737,7,
3745,3,
3749,1,
3751,1,
3754,2,
3757,13,
3771,3,
3776,5,
3782,1,
3784,6,
3804,2,
3840,1,
3864,2,
3893,1,
3895,1,
3897,1,
3902,10,
3913,34,
3953,20,
3974,6,
3984,8,
3993,36,
4038,1,
4096,34,
4131,5,
4137,2,
4140,7,
4150,4,
4176,10,
4256,38,
4304,43,
4348,1,
4352,90,
4447,68,
4520,82,
4608,73,
4682,4,
4688,7,
4696,1,
4698,4,
4704,41,
4746,4,
4752,33,
4786,4,
4792,7,
4800,1,
4802,4,
4808,15,
4824,57,
4882,4,
4888,67,
4959,1,
4992,16,
5024,85,
5121,620,
5743,8,
5761,26,
5792,75,
5888,13,
5902,7,
5920,21,
5952,20,
5984,13,
5998,3,
6002,2,
6016,52,
6070,30,
6103,1,
6108,2,
6155,3,
6176,88,
6272,42,
6400,29,
6432,12,
6448,12,
6480,30,
6512,5,
6528,42,
6576,26,
6656,28,
6912,76,
7019,9,
7424,203,
7678,158,
7840,90,
7936,22,
7960,6,
7968,38,
8008,6,
8016,8,
8025,1,
8027,1,
8029,1,
8031,31,
8064,53,
8118,7,
8126,1,
8130,3,
8134,7,
8144,4,
8150,6,
8160,13,
8178,3,
8182,7,
8305,1,
8319,1,
8336,5,
8400,32,
8450,1,
8455,1,
8458,10,
8469,1,
8473,5,
8484,1,
8486,1,
8488,1,
8490,4,
8495,11,
8508,4,
8517,5,
8526,1,
8579,2,
11264,47,
11312,47,
11360,13,
11380,4,
11392,101,
11520,38,
11568,54,
11631,1,
11648,23,
11680,7,
11688,7,
11696,7,
11704,7,
11712,7,
11720,7,
11728,7,
11736,7,
12293,2,
12330,6,
12337,5,
12347,2,
12353,86,
12441,2,
12445,3,
12449,90,
12540,4,
12549,40,
12593,94,
12704,24,
12784,16,
13312,6582,
19968,20924,
40960,1165,
42775,4,
43008,40,
43072,52,
44032,11172,
63744,302,
64048,59,
64112,106,
64256,7,
64275,5,
64285,12,
64298,13,
64312,5,
64318,1,
64320,2,
64323,2,
64326,108,
64467,363,
64848,64,
64914,54,
65008,12,
65024,16,
65056,4,
65136,5,
65142,135,
65313,26,
65345,26,
65382,89,
65474,6,
65482,6,
65490,6
];

lowercaseLetterCharacterSet = [
97,26,
170,1,
181,1,
186,1,
223,24,
248,8,
257,1,
259,1,
261,1,
263,1,
265,1,
267,1,
269,1,
271,1,
273,1,
275,1,
277,1,
279,1,
281,1,
283,1,
285,1,
287,1,
289,1,
291,1,
293,1,
295,1,
297,1,
299,1,
301,1,
303,1,
305,1,
307,1,
309,1,
311,2,
314,1,
316,1,
318,1,
320,1,
322,1,
324,1,
326,1,
328,2,
331,1,
333,1,
335,1,
337,1,
339,1,
341,1,
343,1,
345,1,
347,1,
349,1,
351,1,
353,1,
355,1,
357,1,
359,1,
361,1,
363,1,
365,1,
367,1,
369,1,
371,1,
373,1,
375,1,
378,1,
380,1,
382,3,
387,1,
389,1,
392,1,
396,2,
402,1,
405,1,
409,3,
414,1,
417,1,
419,1,
421,1,
424,1,
426,2,
429,1,
432,1,
436,1,
438,1,
441,2,
445,3,
454,1,
457,1,
460,1,
462,1,
464,1,
466,1,
468,1,
470,1,
472,1,
474,1,
476,2,
479,1,
481,1,
483,1,
485,1,
487,1,
489,1,
491,1,
493,1,
495,2,
499,1,
501,1,
505,1,
507,1,
509,1,
511,1,
513,1,
515,1,
517,1,
519,1,
521,1,
523,1,
525,1,
527,1,
529,1,
531,1,
533,1,
535,1,
537,1,
539,1,
541,1,
543,1,
545,1,
547,1,
549,1,
551,1,
553,1,
555,1,
557,1,
559,1,
561,1,
563,7,
572,1,
575,2,
578,1,
583,1,
585,1,
587,1,
589,1,
591,69,
661,27,
891,3,
912,1,
940,35,
976,2,
981,3,
985,1,
987,1,
989,1,
991,1,
993,1,
995,1,
997,1,
999,1,
1001,1,
1003,1,
1005,1,
1007,5,
1013,1,
1016,1,
1019,2,
1072,48,
1121,1,
1123,1,
1125,1,
1127,1,
1129,1,
1131,1,
1133,1,
1135,1,
1137,1,
1139,1,
1141,1,
1143,1,
1145,1,
1147,1,
1149,1,
1151,1,
1153,1,
1163,1,
1165,1,
1167,1,
1169,1,
1171,1,
1173,1,
1175,1,
1177,1,
1179,1,
1181,1,
1183,1,
1185,1,
1187,1,
1189,1,
1191,1,
1193,1,
1195,1,
1197,1,
1199,1,
1201,1,
1203,1,
1205,1,
1207,1,
1209,1,
1211,1,
1213,1,
1215,1,
1218,1,
1220,1,
1222,1,
1224,1,
1226,1,
1228,1,
1230,2,
1233,1,
1235,1,
1237,1,
1239,1,
1241,1,
1243,1,
1245,1,
1247,1,
1249,1,
1251,1,
1253,1,
1255,1,
1257,1,
1259,1,
1261,1,
1263,1,
1265,1,
1267,1,
1269,1,
1271,1,
1273,1,
1275,1,
1277,1,
1279,1,
1281,1,
1283,1,
1285,1,
1287,1,
1289,1,
1291,1,
1293,1,
1295,1,
1297,1,
1299,1,
1377,39,
7424,44,
7522,22,
7545,34,
7681,1,
7683,1,
7685,1,
7687,1,
7689,1,
7691,1,
7693,1,
7695,1,
7697,1,
7699,1,
7701,1,
7703,1,
7705,1,
7707,1,
7709,1,
7711,1,
7713,1,
7715,1,
7717,1,
7719,1,
7721,1,
7723,1,
7725,1,
7727,1,
7729,1,
7731,1,
7733,1,
7735,1,
7737,1,
7739,1,
7741,1,
7743,1,
7745,1,
7747,1,
7749,1,
7751,1,
7753,1,
7755,1,
7757,1,
7759,1,
7761,1,
7763,1,
7765,1,
7767,1,
7769,1,
7771,1,
7773,1,
7775,1,
7777,1,
7779,1,
7781,1,
7783,1,
7785,1,
7787,1,
7789,1,
7791,1,
7793,1,
7795,1,
7797,1,
7799,1,
7801,1,
7803,1,
7805,1,
7807,1,
7809,1,
7811,1,
7813,1,
7815,1,
7817,1,
7819,1,
7821,1,
7823,1,
7825,1,
7827,1,
7829,7,
7841,1,
7843,1,
7845,1,
7847,1,
7849,1,
7851,1,
7853,1,
7855,1,
7857,1,
7859,1,
7861,1,
7863,1,
7865,1,
7867,1,
7869,1,
7871,1,
7873,1,
7875,1,
7877,1,
7879,1,
7881,1,
7883,1,
7885,1,
7887,1,
7889,1,
7891,1,
7893,1,
7895,1,
7897,1,
7899,1,
7901,1,
7903,1,
7905,1,
7907,1,
7909,1,
7911,1,
7913,1,
7915,1,
7917,1,
7919,1,
7921,1,
7923,1,
7925,1,
7927,1,
7929,1,
7936,8,
7952,6,
7968,8,
7984,8,
8000,6,
8016,8,
8032,8,
8048,14,
8064,8,
8080,8,
8096,8,
8112,5,
8118,2,
8126,1,
8130,3,
8134,2,
8144,4,
8150,2,
8160,8,
8178,3,
8182,2,
8305,1,
8319,1,
8458,1,
8462,2,
8467,1,
8495,1,
8500,1,
8505,1,
8508,2,
8518,4,
8526,1,
8580,1,
11312,47,
11361,1,
11365,2,
11368,1,
11370,1,
11372,1,
11380,1,
11382,2,
11393,1,
11395,1,
11397,1,
11399,1,
11401,1,
11403,1,
11405,1,
11407,1,
11409,1,
11411,1,
11413,1,
11415,1,
11417,1,
11419,1,
11421,1,
11423,1,
11425,1,
11427,1,
11429,1,
11431,1,
11433,1,
11435,1,
11437,1,
11439,1,
11441,1,
11443,1,
11445,1,
11447,1,
11449,1,
11451,1,
11453,1,
11455,1,
11457,1,
11459,1,
11461,1,
11463,1,
11465,1,
11467,1,
11469,1,
11471,1,
11473,1,
11475,1,
11477,1,
11479,1,
11481,1,
11483,1,
11485,1,
11487,1,
11489,1,
11491,2,
11520,38,
64256,7,
64275,5
];

nonBaseCharacterSet = [
768,112,
1155,4,
1160,2,
1425,45,
1471,1,
1473,2,
1476,2,
1479,1,
1552,6,
1611,20,
1648,1,
1750,7,
1758,7,
1767,2,
1770,4,
1809,1,
1840,27,
1958,11,
2027,9,
2305,3,
2364,1,
2366,16,
2385,4,
2402,2,
2433,3,
2492,1,
2494,7,
2503,2,
2507,3,
2519,1,
2530,2,
2561,3,
2620,1,
2622,5,
2631,2,
2635,3,
2672,2,
2689,3,
2748,1,
2750,8,
2759,3,
2763,3,
2786,2,
2817,3,
2876,1,
2878,6,
2887,2,
2891,3,
2902,2,
2946,1,
3006,5,
3014,3,
3018,4,
3031,1,
3073,3,
3134,7,
3142,3,
3146,4,
3157,2,
3202,2,
3260,1,
3262,7,
3270,3,
3274,4,
3285,2,
3298,2,
3330,2,
3390,6,
3398,3,
3402,4,
3415,1,
3458,2,
3530,1,
3535,6,
3542,1,
3544,8,
3570,2,
3633,1,
3636,7,
3655,8,
3761,1,
3764,6,
3771,2,
3784,6,
3864,2,
3893,1,
3895,1,
3897,1,
3902,2,
3953,20,
3974,2,
3984,8,
3993,36,
4038,1,
4140,7,
4150,4,
4182,4,
4959,1,
5906,3,
5938,3,
5970,2,
6002,2,
6070,30,
6109,1,
6155,3,
6313,1,
6432,12,
6448,12,
6576,17,
6600,2,
6679,5,
6912,5,
6964,17,
7019,9,
7616,11,
7678,2,
8400,32,
12330,6,
12441,2,
43010,1,
43014,1,
43019,1,
43043,5,
64286,1,
65024,16
];

punctuationCharacterSet = [
33,3,
37,6,
44,4,
58,2,
63,2,
91,3,
95,1,
123,1,
125,1,
161,1,
171,1,
183,1,
187,1,
191,1,
894,1,
903,1,
1370,6,
1417,2,
1470,1,
1472,1,
1475,1,
1478,1,
1523,2,
1548,2,
1563,1,
1566,2,
1642,4,
1748,1,
1792,14,
2039,3,
2404,2,
2416,1,
3572,1,
3663,1,
3674,2,
3844,15,
3898,4,
3973,1,
4048,2,
4170,6,
4347,1,
4961,8,
5741,2,
5787,2,
5867,3,
5941,2,
6100,3,
6104,3,
6144,11,
6468,2,
6622,2,
6686,2,
7002,7,
8208,24,
8240,20,
8261,13,
8275,12,
8317,2,
8333,2,
9001,2,
10088,14,
10181,2,
10214,6,
10627,22,
10712,4,
10748,2,
11513,4,
11518,2,
11776,24,
11804,2,
12289,3,
12296,10,
12308,12,
12336,1,
12349,1,
12448,1,
12539,1,
43124,4,
64830,2,
65040,10,
65072,35,
65108,14,
65123,1,
65128,1,
65130,2,
65281,3,
65285,6,
65292,4,
65306,2,
65311,2,
65339,3,
65343,1,
65371,1,
65373,1
];

uppercaseLetterCharacterSet = [
65,26,
192,23,
216,7,
256,1,
258,1,
260,1,
262,1,
264,1,
266,1,
268,1,
270,1,
272,1,
274,1,
276,1,
278,1,
280,1,
282,1,
284,1,
286,1,
288,1,
290,1,
292,1,
294,1,
296,1,
298,1,
300,1,
302,1,
304,1,
306,1,
308,1,
310,1,
313,1,
315,1,
317,1,
319,1,
321,1,
323,1,
325,1,
327,1,
330,1,
332,1,
334,1,
336,1,
338,1,
340,1,
342,1,
344,1,
346,1,
348,1,
350,1,
352,1,
354,1,
356,1,
358,1,
360,1,
362,1,
364,1,
366,1,
368,1,
370,1,
372,1,
374,1,
376,2,
379,1,
381,1,
385,2,
388,1,
390,2,
393,3,
398,4,
403,2,
406,3,
412,2,
415,2,
418,1,
420,1,
422,2,
425,1,
428,1,
430,2,
433,3,
437,1,
439,2,
444,1,
452,2,
455,2,
458,2,
461,1,
463,1,
465,1,
467,1,
469,1,
471,1,
473,1,
475,1,
478,1,
480,1,
482,1,
484,1,
486,1,
488,1,
490,1,
492,1,
494,1,
497,2,
500,1,
502,3,
506,1,
508,1,
510,1,
512,1,
514,1,
516,1,
518,1,
520,1,
522,1,
524,1,
526,1,
528,1,
530,1,
532,1,
534,1,
536,1,
538,1,
540,1,
542,1,
544,1,
546,1,
548,1,
550,1,
552,1,
554,1,
556,1,
558,1,
560,1,
562,1,
570,2,
573,2,
577,1,
579,4,
584,1,
586,1,
588,1,
590,1,
902,1,
904,3,
908,1,
910,2,
913,17,
931,9,
978,3,
984,1,
986,1,
988,1,
990,1,
992,1,
994,1,
996,1,
998,1,
1000,1,
1002,1,
1004,1,
1006,1,
1012,1,
1015,1,
1017,2,
1021,51,
1120,1,
1122,1,
1124,1,
1126,1,
1128,1,
1130,1,
1132,1,
1134,1,
1136,1,
1138,1,
1140,1,
1142,1,
1144,1,
1146,1,
1148,1,
1150,1,
1152,1,
1162,1,
1164,1,
1166,1,
1168,1,
1170,1,
1172,1,
1174,1,
1176,1,
1178,1,
1180,1,
1182,1,
1184,1,
1186,1,
1188,1,
1190,1,
1192,1,
1194,1,
1196,1,
1198,1,
1200,1,
1202,1,
1204,1,
1206,1,
1208,1,
1210,1,
1212,1,
1214,1,
1216,2,
1219,1,
1221,1,
1223,1,
1225,1,
1227,1,
1229,1,
1232,1,
1234,1,
1236,1,
1238,1,
1240,1,
1242,1,
1244,1,
1246,1,
1248,1,
1250,1,
1252,1,
1254,1,
1256,1,
1258,1,
1260,1,
1262,1,
1264,1,
1266,1,
1268,1,
1270,1,
1272,1,
1274,1,
1276,1,
1278,1,
1280,1,
1282,1,
1284,1,
1286,1,
1288,1,
1290,1,
1292,1,
1294,1,
1296,1,
1298,1,
1329,38,
4256,38,
7680,1,
7682,1,
7684,1,
7686,1,
7688,1,
7690,1,
7692,1,
7694,1,
7696,1,
7698,1,
7700,1,
7702,1,
7704,1,
7706,1,
7708,1,
7710,1,
7712,1,
7714,1,
7716,1,
7718,1,
7720,1,
7722,1,
7724,1,
7726,1,
7728,1,
7730,1,
7732,1,
7734,1,
7736,1,
7738,1,
7740,1,
7742,1,
7744,1,
7746,1,
7748,1,
7750,1,
7752,1,
7754,1,
7756,1,
7758,1,
7760,1,
7762,1,
7764,1,
7766,1,
7768,1,
7770,1,
7772,1,
7774,1,
7776,1,
7778,1,
7780,1,
7782,1,
7784,1,
7786,1,
7788,1,
7790,1,
7792,1,
7794,1,
7796,1,
7798,1,
7800,1,
7802,1,
7804,1,
7806,1,
7808,1,
7810,1,
7812,1,
7814,1,
7816,1,
7818,1,
7820,1,
7822,1,
7824,1,
7826,1,
7828,1,
7840,1,
7842,1,
7844,1,
7846,1,
7848,1,
7850,1,
7852,1,
7854,1,
7856,1,
7858,1,
7860,1,
7862,1,
7864,1,
7866,1,
7868,1,
7870,1,
7872,1,
7874,1,
7876,1,
7878,1,
7880,1,
7882,1,
7884,1,
7886,1,
7888,1,
7890,1,
7892,1,
7894,1,
7896,1,
7898,1,
7900,1,
7902,1,
7904,1,
7906,1,
7908,1,
7910,1,
7912,1,
7914,1,
7916,1,
7918,1,
7920,1,
7922,1,
7924,1,
7926,1,
7928,1,
7944,8,
7960,6,
7976,8,
7992,8,
8008,6,
8025,1,
8027,1,
8029,1,
8031,1,
8040,8,
8072,8,
8088,8,
8104,8,
8120,5,
8136,5,
8152,4,
8168,5,
8184,5,
8450,1,
8455,1,
8459,3,
8464,3,
8469,1,
8473,5,
8484,1,
8486,1,
8488,1,
8490,4,
8496,4,
8510,2,
8517,1,
8579,1,
11264,47,
11360,1,
11362,3,
11367,1,
11369,1,
11371,1,
11381,1,
11392,1,
11394,1,
11396,1,
11398,1,
11400,1,
11402,1,
11404,1,
11406,1,
11408,1,
11410,1,
11412,1,
11414,1,
11416,1,
11418,1,
11420,1,
11422,1,
11424,1,
11426,1,
11428,1,
11430,1,
11432,1,
11434,1,
11436,1,
11438,1,
11440,1,
11442,1,
11444,1,
11446,1,
11448,1,
11450,1,
11452,1,
11454,1,
11456,1,
11458,1,
11460,1,
11462,1,
11464,1,
11466,1,
11468,1,
11470,1,
11472,1,
11474,1,
11476,1,
11478,1,
11480,1,
11482,1,
11484,1,
11486,1,
11488,1,
11490,1
];

whitespaceAndNewlineCharacterSet = [
9,5,
32,1,
133,1,
160,1,
5760,1,
8192,12,
8232,2,
8239,1,
8287,1
];

whitespaceCharacterSet = [
9,1,
32,1,
160,1,
5760,1,
8192,12,
8239,1,
8287,1
];
