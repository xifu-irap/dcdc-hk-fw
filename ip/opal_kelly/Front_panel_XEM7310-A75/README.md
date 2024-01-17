# Directory Structure

To get the corresponding files, see the internal doc.

## Simu sub-directory

The "simu" directory contains simulation files for the FrontPanelUSB (Opal Kelly USB3 IP).
  The simulations files are listed below:
    . mappings.vhd
    . okBTPipeIn.vhd
    . okBTPipeOut.vhd
    . okDualHost.vhd
    . okHost.vhd
    . okLibrary_sim.vhd
    . okPipeIn.vhd
    . okPipeOut.vhd
    . okRegisterBridge.vhd
    . okTriggerIn.vhd
    . okTriggerOut.vhd
    . okWireIn.vhd
    . okWireOR.vhd
    . okWireOut.vhd
    . parameters.vhd

## syn sub-directory
The "syn" directory contains encrypted synthetized files (compiled for 2021) of the USB IP provided by the Opal Kelly vendor.

  The encrypted files must be compatible with Vivado 2022.1. The time between the currently vivado version and the vivado version used by the vendor to encrypt their VHDL files must be inferior to 5 years. Otherwise, the currently vivado version can't uncrypt the files.

  The synthetized files are listed below:
    . okBTPipeIn.v
    . okBTPipeOut.v
    . okCoreHarness.v
    . okLibrary.v
    . okLibrary.vhd
    . okPipeIn.v
    . okPipeOut.v
    . okRegisterBridge.v
    . okTriggerIn.v
    . okTriggerOut.v
    . okWireIn.v
    . okWireOut.v