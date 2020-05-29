# Custom Tests. Ported from AfterBurner 2 Source Code. 

.include "config.inc"
.include "io.inc"
.include "ramless.inc"


# Test Multiplier IC (315-5248)
# Output:
# d0 == 0 (Good)
# d0 != 0 (Bad)

.global testMultiplier
testMultiplier:
    move.w  #0xFFF,%d6              /* Number of tests to run */
_next1:
    CALL Random                     /* Put Random Number in d0 */
    move.w  %d0,%d2
    CALL Random                     /* Put Random Number in d0 */
    move.w  %d0,-0x4000(%a0)
    move.w  %d2,-0x3FFE(%a0)
    cmp.w   -0x4000(%a0),%d0
    bne.s   _done1
    cmp.w   -0x3FFE(%a0),%d2
    bne.s   _done1
    CALL Random                     /* Put Random Number in d0 */
    move.w  %d0,%d2
    CALL Random                     /* Put Random Number in d0 */
    move.w  %d0,-0x3FFE(%a0)
    move.w  %d2,-0x4000(%a0)
    cmp.w   -0x3FFE(%a0),%d0
    bne.s   _done1
    cmp.w   -0x4000(%a0),%d2
    bne.s   _done1
    dbf     %d6,_next1
_done1:
    sne     %d0
    ext.w   %d0
    RETURN_A5

# Test Divider IC (315-5249)
# Output:
# d0 == 0 (Good)
# d0 != 0 (Bad)
    
.global testDivider
testDivider:
    move.w  #0xFFF,%d6              /* Number of tests to run */
_next2:
    CALL Random                     /* Put Random Number in d0 */
    move.w  %d0,%d2
    CALL Random                     /* Put Random Number in d0 */
    move.l  %d0,0(%a0)
    move.w  %d2,0x14(%a0)
    cmp.l   0(%a0),%d0
    bne.s   _done2
    cmp.w   4(%a0),%d2
    bne.s   _done2
    CALL Random                     /* Put Random Number in d0 */
    move.w  %d0,%d2
    CALL Random                     /* Put Random Number in d0 */
    move.w  %d2,4(%a0)
    move.l  %d0,0x10(%a0)
    cmp.w   4(%a0),%d2
    bne.s   _done2
    cmp.l   0(%a0),%d0
    bne.s   _done2
    dbf     %d6,_next2
_done2:
    sne     %d0
    ext.w   %d0
    RETURN_A5
    
# Test Comparator IC (315-5250)
# Output:
# d0 == 0 (Good)
# d0 != 0 (Bad)

.global testComparator
testComparator:
    move.w  #0xFFF,%d6              /* Number of tests to run */
_next3:
    CALL Random                     /* Put Random Number in d0 */
    move.w  %d0,%d4
    CALL Random                     /* Put Random Number in d0 */
    move.w  %d0,%d2
    CALL Random                     /* Put Random Number in d0 */
    move.w  %d0,0x4000(%a0)
    move.w  %d2,0x4002(%a0)
    move.w  %d4,0x4004(%a0)
    cmp.w   0x4000(%a0),%d0
    bne.s   _done3
    cmp.w   0x4002(%a0),%d2
    bne.s   _done3
    cmp.w   0x4004(%a0),%d4
    bne.s   _done3
    dbf     %d6,_next3
_done3:
    sne     %d0
    ext.w   %d0
    RETURN_A5
    
# Random Number Generator
#
# In Use:
# d0 = Work Variable
# d1 = Current Seed
# d7 = Stored Seed
#
# Output:
# d0 = Random Number

Random:
    #move.l  (seed_set).w,d1
    move.l  %d7,%d1
    bne.w   _seedset
    move.l  #0x2A6D365A,%d1
_seedset:
    move.l  %d1,%d0
    asl.l   #2,%d1
    add.l   %d0,%d1
    asl.l   #3,%d1
    add.l   %d0,%d1
    move.w  %d1,%d0
    swap    %d1
    add.w   %d1,%d0
    move.w  %d0,%d1
    swap    %d1
    #move.l  d1,(seed_set).w
    move.l  %d1,%d7
    RETURN
   