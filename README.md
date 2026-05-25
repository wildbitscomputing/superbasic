# SuperBASIC

Modern BASIC dialect for Wildbits/Foenix F256 computers.

## Usage

SuperBASIC Reference Manual PDF:
[reference/source/f256jr_basic_ref.pdf](reference/source/f256jr_basic_ref.pdf)

## Contributing

We’d love your help in making SuperBASIC the best 8-/16-bit BASIC interpreter out there!

Whether you’re fixing a bug, improving performance, or simply correcting a typo in the manual, your contribution is greatly appreciated. By contributing, you agree that your work will be licensed under the [MIT License](./LICENSE).

To keep our history clean and make it easier to automate [releases](#releasing-a-new-version), we follow the [Conventional Commits](https://www.conventionalcommits.org/) style for commit messages. Here are some examples:

```
git log --oneline

5bd1cf7 feat: add `at` modifier for `print`
63b442a fix: `print at 59, 79; "*";` causes the screen to scroll
089f839 perf: improve `load` performance
9278ca9 refmanual: add `call` statement docs
1c43a28 docs: README fixes, MAME testing instructions
78e6ad2 build: support for gen 2 builds
c21ae79 chore: enable line ending normalization
```

When we generate release notes, the first four categories (`feat`, `fix`, `perf`, and `refmanual`) appear in their own sections, while everything else is grouped under _Internal_.

## Local development

You need Make, Python and 64tass assembler on your machine.

### Building

Standard development build:

```
make -C source -B build
```

Full rebuild, pulls latest kernel APIs:

```
make -C source -B updatekernel build
```

The build output is stored in the `.build` directory at the repository root.

### Testing

#### MAME

[MAME](https://www.mamedev.org/) is an emulation framework for a wide variety of computer
architectures, old and new alike. A work-in-progress fork of MAME for F256K is available
at https://github.com/dtremblay/mame.

Assuming you have the above repository cloned side-by-side with the `superbasic` repo,
you can run the following commands to test your build in MAME F256K:

```
cd mame
cp -f ../superbasic/.build/sb*.bin roms/f256k/    # copy over SuperBASIC ROMs
./f256 f256 -window -resolution 1280x960          # run the emulator
```

Note that because MAME embeds CRC checksums for all ROMs, you'll see warnings similar to
the following:

```
sb01.bin WRONG CHECKSUMS:
    EXPECTED: CRC(21f06e73) SHA1(bbeefb52d4b126b61367169c21599180f3358af7)
       FOUND: CRC(88ece5fe) SHA1(467a8a3fa1b5b686235439d023dd2248895f9ab7)
sb03.bin WRONG CHECKSUMS:
    EXPECTED: CRC(653f849d) SHA1(65942d98f26b86499e6359170aa2d0c6e16124ff)
       FOUND: CRC(0f3b2b61) SHA1(b540fa85b4906bad5345eba525b928534333b1f1)
sb04.bin WRONG CHECKSUMS:
    EXPECTED: CRC(f4aa6049) SHA1(11f02fee6ec412f0c96b27b0b149f72cf1770d15)
       FOUND: CRC(81a3ddb7) SHA1(4cccecb817bd5b358acbf3b2d44f7af71dfa89f3)
WARNING: the machine might not run correctly.
```

These warnings can be safely ignored.

#### Real hardware

You can upload it over a USB cable to the debug port on your F256 machine using FoenixMgr.

This doc doesn't cover setting that up, but once you have it set up you should be able to
try out your build using the `--flash-bulk` command.

Example on Mac:

```
❯ cd .build
❯ python3 ~/FoenixMgr/fnxmgr.py --port /dev/cu.usbmodemR23963534611 --flash-bulk bulk.csv
Attempting to program sector 0x3F with lockout.bin
Binary file uploaded...
Flash sector erased...
Flash sector programmed...
Attempting to program sector 0x01 with sb01.bin
     ...
```

## Releasing a new version

To ensure quality and reproducibility, official releases are handled through GitHub workflows.

The [release PR preparation](/.github/workflows/prepare-release-pr.yml) workflow monitors pushes to `main` and automatically creates or updates [a release PR](https://github.com/wildbitscomputing/superbasic/pulls?q=is%3Apr+is%3Aopen+label%3Arelease) that includes all unreleased changes. This PR includes a log of contributions and is assigned a version based on the major and minor numbers in [`source/Makefile`](/source/Makefile), with the patch number determined by the date of the latest contribution.

Merging the release PR updates the [`VERSION`](/VERSION) and [`CHANGESET.md`](/CHANGESET.md) files, then triggers the [final release](/.github/workflows/release.yml) workflow, which publishes the GitHub release.

## Additional resources

- [Wildbits Documentation Wiki](https://f256wiki.wildbitscomputing.com)
- [More information on flashing SuperBASIC to your machine](https://f256wiki.wildbitscomputing.com/index.php?title=Kernel_%26_SuperBASIC_Updates)
- [More information on MAME for Wildbits/F256](https://f256wiki.wildbitscomputing.com/index.php?title=Emulation#MAME)
- [MicroKernel](https://github.com/wildbitscomputing/MicroKernel)
- [Command Line USB upload tool](https://github.com/pweingar/FoenixMgr)
