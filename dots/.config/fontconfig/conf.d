<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
  <match target="font">
    <edit name="rgba" mode="assign">
      <const>none</const>
    </edit>
  </match>

  <!-- Fix for: arabic fonts rendering in Noto Nastaliq Urdu | affects Chromium, Discord (maybe all chromium based apps, but not Spotify somehow) -->
  <match target="pattern">
    <test compare="eq" name="family">
      <string>sans-serif</string>
    </test>
    <edit name="family" mode="prepend" binding="strong">
      <string>Noto Sans Arabic</string>
    </edit>
  </match>
</fontconfig>
