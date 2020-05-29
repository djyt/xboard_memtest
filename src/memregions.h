#ifndef __MEMREGIONS_H__
#define __MEMREGIONS_H__

// RAM regions to test for the current architecture.

// Region flags (byte).
enum
{
	RAM_FLAG_REMOTE = 0x80,
};

// RPC calls for the second CPU.
// These are game-specific. 0..2 are reserved.
#define NAKED // __declspec(naked)
typedef NAKED void RESTORECALLBACK();

#pragma pack(push,2)
struct RAMREGION 
{
	const char*    name;		          // Keep these in all capitals if the ROM character set requires this.
	unsigned long  address;		          // Base address to test.
	unsigned short interleave;	          // Interleave step. Set to 1 to test all consecutive bytes, set to 2 to skip every other byte (for 16 bit data bus).
	unsigned int   size;			      // Size in bytes.
	union 
	{
	  RESTORECALLBACK* pRestoreCallback;  // Called after the test. nullptr for none.
	  unsigned int     remoteRestoreIdx;  // Remote callback index. 0 for none.
	};
	unsigned char  flags;                 // Bit 7: Remote (second CPU).
//	bool*          pConditionVar;         // Can point to a boolean that enables or disables the test.
};
#pragma pack(pop)

#endif // __MEMREGIONS_H__
