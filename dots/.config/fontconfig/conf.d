<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
  <match target="font">
    <edit name="rgba" mode="assign">
      <const>none</const>
    </edit>
  </match>
  <match target="pattern">
    <test name="lang">
      <string>ar</string>
    </test>
    <edit name="family" mode="prepend">
      <string>Noto Sans Arabic</string>
    </edit>
  </match>
</fontconfig>
