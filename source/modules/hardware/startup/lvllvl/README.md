# Updating the banner

- Go to https://lvllvl.com/
- Click "Open Local File..."
- Select `banner.json` and click "Open"
- Make your changes
- In the top menu, select Export > JSON... to open the Export JSON dialog
- Enter the file name and click "OK" to download the updated banner definition

# Updating text placement

The banner includes placeholders for machine info, as well as versions of the
kernel software and SuperBASIC itself. The colors and placement of this text are
defined in `banner_text.json`.

Note that this is information does not come directly from lvllvl and must be
updated manually whenever the banner layout changes in a way that affects the
color or the placement of the text.

# Updating the pallete

`banner.json` includes the 16-color palette definition under the `colorPalette`
key, but the color values are saved as decimal ARGB values and are therefore
difficult to dechypher without additional tooling. To make it easier to edit and
examine the palette, a standalone, plain-text palette definition is available in
the `palette.hex` file. This file can be edited locally and loaded in lvllvl as
follows:

- Make sure the color panel is shown: Interface > Colour Palette Panel
- In the Colour Palette Panel, click "Load Palette...", then "Choose file..."
- Select `palette.hex` and click "Open"
- In the Load / Import Colour Palette dialog, change the Colours Across setting
  to 8 and clock "OK"

You can also edit the palette using lvllvl's built-in palette editor:

- In the Colour Palette Panel, click "Edit Palette..."
- Make your changes
- Click "Save As...", change the file name to `palette` and fhe format to "Hex"
  and click "OK"
