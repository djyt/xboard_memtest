#include "memregions.h"

// RPC calls for the second CPU.
// These are game-specific. 0..2 are reserved.
enum
{
	RPC_SwapRoad = 3,
};

// Callbacks.
extern NAKED void InitPalette();
extern NAKED void InitTile();
extern NAKED void SaveText();
extern NAKED void RestoreText();
extern NAKED void ResetSubCPU(); // Give us back our nice blue color (and a valid state).
extern NAKED void EnableIRQ4();
extern NAKED void SwapRoad();
extern NAKED void WaitVBlank();

// RAM regions to test for the current architecture.
const struct RAMREGION ramInfo[] = 
{
    //  080000-09FFFF : Work RAM #2 (16K) (IC60, 55)
	{ "MAIN IC60 ", 0x80000, 2, 0x4000 },
	{ "MAIN IC55 ", 0x80001, 2, 0x4000 },
    //  0A0000-0BFFFF : Work RAM #1 (16K) (IC61, 56)
	{ "MAIN IC61 ", 0xA0000, 2, 0x4000 },
 	{ "MAIN IC56 ", 0xA0001, 2, 0x4000, EnableIRQ4 },  
    // 280000-29FFFF : RAM (16K) (IC31,22) [Verified]
	{ "SUB  IC22 ", 0x280000, 2, 0x4000 },
	{ "SUB  IC31 ", 0x280001, 2, 0x4000 },
    // 2A0000-2BFFFF : RAM (16K) (IC32,23) [Verified]
	{ "SUB  IC23 ", 0x2A0000, 2, 0x4000 },
	{ "SUB  IC32 ", 0x2A0001, 2, 0x4000, ResetSubCPU },
    // 2EC000-2EDFFF : Road RAM (4K accessible of 8K total) (IC39,38)
    { "ROAD LSB0 ", 0x2EC000, 2, 0x1000 },
	{ "ROAD MSB0 ", 0x2EC001, 2, 0x1000, SwapRoad },
	{ "ROAD LSB1 ", 0x2EC000, 2, 0x1000 },
	{ "ROAD MSB1 ", 0x2EC001, 2, 0x1000, SwapRoad },
    // 0C0000-0CFFFF : Tile RAM (64K) (IC135,34)
	{ "TILE IC135", 0x0C0000, 2, 0x10000 },
	{ "TILE IC34 ", 0x0C0001, 2, 0x10000, InitTile },
    // 120000-12FFFF : Color RAM (16K)
	{ "PAL  LSB  ", 0x120000, 2, 0x4000 },
	{ "PAL  MSB  ", 0x120001, 2, 0x4000, InitPalette },
    // 100000-10FFFF : Sprite RAM (4K accessible of 8K total)
	{ "SPR  LSB  ", 0x100000, 2, 0x1000, WaitVBlank },
	{ "SPR  MSB  ", 0x100001, 2, 0x1000, SaveText },
    // 0D0000-0DFFFF : Text RAM (4K) (IC133,132)
    { "TEXT IC133", 0x0D0000, 2, 0x1000 }, // TMM2115 (2KB x 2)
	{ "TEXT IC132", 0x0D0001, 2, 0x1000, RestoreText },
    
	// IC95 is een multiplexert/selector geval. SAB17..19 (1 t/m 19 op de CPU). LDS en UDS hebben we (byte select).
	// Ok dus CPU heeft gewoon geen A0. Nice. LDS=bit 0..7; UDS=bit 8..15.
	// 128k per rom bank (2 chips). Gebruikt bits 0..16 (op de M68k)
	// 
	//               LDS(DB 0..7)   UDS(DB 8..15)
	// 0x0200000     IC58           IC76
	// 0x0220000     IC57           IC75
	// 0x0240000     IC56           IC74
	// Als A17 en A18 aan (0x60000), dan gaan we naar RAM. A14 hoog -> !RAM1 hoog. !RAM1 -> !CE -> IC114 aan.
	//
	// Subram = 2x8k, dus extra selector op SAB14.
	// 0x0260000     IC54           IC72
	// 0x0220000     IC55(SA14=CE)  IC73(SA14=CE)	// Inverter (LS04 IC??) sets !CE to the inverse.

	// Big endian 16 bit data locations:
	// A 16-bit read to address #0 will load the high (first) byte at position 0 over lines D8..15, and the low byte at position 1 from lines D0..7.
	
	// 54 is the lower half due to the inverter (LS04) A14 to CE.
	// *** Note that sub ram needs to be untouched by the secondary CPU (including interrupts) during testing! ***
	//{ " SUB IC72 ",  0x260000, 2, 0x4000 }, // 32k sub ram; 4 chips. ic 73+72(db8..15); 55+54(db0..7); 
	//{ " SUB IC54 ",  0x260001, 2, 0x4000 },
	//{ " SUB IC73 ",  0x264000, 2, 0x4000 },
	//{ " SUB IC55 ",  0x264001, 2, 0x4000, ResetSubCPU }, // CE zit aan S.AD14; !CE aan !S.RAM. Ok dit klopt wel.

	// IC20 WE0 D0..7
	// IC21 WE2 D8..15
	// IC38 WE1 D0..7
	// IC39 WE3 D8..15
	// WE0..3 go to IC35 (LS155 = DUAL 4 OF 1 DECODER):
	//   /1G=/SLWR, /2G=/SUWR, A=/ROAD, B=IC7 pin 10 (dual flip flop)
	// Goes to IC98 (LS241)
	
	// Not verified which half this is which. Could also be 21/20.
//	{ "ROAD LSB0",  0x80000, 2, 0x1000, (void*)0, RAM_FLAG_REMOTE },
//	{ "ROAD MSB0",  0x80001, 2, 0x1000, (void*)RPC_SwapRoad, RAM_FLAG_REMOTE },
//	{ "ROAD LSB1",  0x80000, 2, 0x1000, (void*)0, RAM_FLAG_REMOTE },
//	{ "ROAD MSB1",  0x80001, 2, 0x1000, (void*)RPC_SwapRoad, RAM_FLAG_REMOTE },

	// Test road from main CPU, assuming that swapping works.	
	//{ "ROAD LSB0 ",  0x280000, 2, 0x1000 },
	//{ "ROAD MSB0 ",  0x280001, 2, 0x1000, SwapRoad },
	//{ "ROAD LSB1 ",  0x280000, 2, 0x1000 },
	//{ "ROAD MSB1 ",  0x280001, 2, 0x1000, SwapRoad },
	
	// VIDEO BOARD.

	// IC#s verified.
	//{ "TILE IC64 ",  0x100000, 2, 0x10000 }, // HM65256 (32KB x 2)
	//{ "TILE IC62 ",  0x100001, 2, 0x10000, InitTile }, // TileCallback },

	// Hmm. Schematic says 2x 8KB RAM. What is up with A12?
	// Goes to IC98 (LS241)
	//{ " PAL IC74 ",  0x120000, 2, 0x1000 },
	//{ " PAL IC75 ",  0x120001, 2, 0x1000, InitPalette },

	// Sprites: 2x TMM2018 (2KB x 2)
	// Sprite RAM is special; A10(A12) can only be switched by the 315-5211 sprite generator for double buffering.
	// This means we can only test one half at a time, and we can't test bit 12 of the address bus.
	//{ " SPR IC30 ",  0x130000, 2, 0x800, WaitVBlank },
	//{ " SPR IC29 ",  0x130001, 2, 0x800, SaveText },

	//{ "TEXT IC50 ",  0x110000, 2, 0x1000 }, // TMM2115 (2KB x 2)
	//{ "TEXT IC63 ",  0x110001, 2, 0x1000, RestoreText },

    // All done.
	{ 0 },
};
