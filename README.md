# Sega X-Board Memory Test Software

![0000](https://user-images.githubusercontent.com/2414449/114413188-a9772900-9ba5-11eb-97b0-c955caf2604f.png)

A set of ROM images to test the RAM ICs and custom chips on Sega X-Board hardware (AfterBurner, Thunderblade etc.). It is more robust than the on-board tests and stands a better chance of running on a dead boardset.

- It does not require working main RAM to actually run the main RAM test.
- Remove all sub CPU EPROMs when installing (IC 20, IC 29 etc), as these interfere with the results.
- It requires a vanilla 68K CPU to be installed, not the FD1094 security processor present on some X-Board games.
- The palette will be incorrect when used on games other than AfterBurner. But it should still operate correctly. 

This was not previously released, because I hadn't verified the IC labeling on hardware. However, a number of people have already used this software to successfully fix PCBs. Therefore, I figured I should get this out there and address problems as they are reported.

This is based on the OutRun Memory Test.
