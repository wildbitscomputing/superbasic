## 1.2.2026-09-01

### Features

- Banked program memory, FRE() function, array region, boot ROM layout ([`b2e99a2`](https://github.com/FoenixRetro/f256-superbasic/commit/b2e99a2fb5f00e207b9053aa5d354c6d571b85be))
- Add STEP support for FOR loops ([`df4639f`](https://github.com/FoenixRetro/f256-superbasic/commit/df4639f69b667a42dac8262dad7e8ec6172bba61))
- Add scroll navigation, line-wrap tracking, and wrap-aware editing ([`bd83aa5`](https://github.com/FoenixRetro/f256-superbasic/commit/bd83aa5a540d6ce2221669467cf57b05478d2e19))
- Remap editing keys ([`174c599`](https://github.com/FoenixRetro/f256-superbasic/commit/174c59944eedee095ea402475b08b6cf77fb9645))
- Add LOMEM command for program page allocation ([#114](https://github.com/FoenixRetro/f256-superbasic/issues/114)) ([`ee21fce`](https://github.com/FoenixRetro/f256-superbasic/commit/ee21fce068b1d4b8b26dfd711dad1b44e1a837e6))
- Add user-defined functions (`fn`/`endfn`) ([#115](https://github.com/FoenixRetro/f256-superbasic/issues/115)) ([`59af723`](https://github.com/FoenixRetro/f256-superbasic/commit/59af7234360e4647271116135a70a6316ea693f4))
- DIR improvements, CD command, and slot 3 module architecture ([#118](https://github.com/FoenixRetro/f256-superbasic/issues/118)) ([`8bf6578`](https://github.com/FoenixRetro/f256-superbasic/commit/8bf6578a9cc8a1d4251f5250671c5412c7c24393))
- Allow for an optional variable reference in `next` ([#121](https://github.com/FoenixRetro/f256-superbasic/issues/121)) ([`71916bc`](https://github.com/FoenixRetro/f256-superbasic/commit/71916bc95b1a3eed7a0bfa6ed11a28d66931e813))
- `tab()` modifier for `print`/`input` ([#122](https://github.com/FoenixRetro/f256-superbasic/issues/122)) ([`0bd4e67`](https://github.com/FoenixRetro/f256-superbasic/commit/0bd4e67b0a0e79922e4e0329bb52b10285617274))
- Page split on mid-page insert for multi-page programs ([#123](https://github.com/FoenixRetro/f256-superbasic/issues/123)) ([`6ff2dec`](https://github.com/FoenixRetro/f256-superbasic/commit/6ff2decc1f2457de7c1c129ed5fdeb93d6c533f8))
- Updated startup banner ([#124](https://github.com/FoenixRetro/f256-superbasic/issues/124)) ([`d5bff89`](https://github.com/FoenixRetro/f256-superbasic/commit/d5bff89028ea8e4422ea2276a6bcb988862456f6))
- Joystick 1 support in `joyx`/`joyy`/`joyb` functions ([`9bdd763`](https://github.com/FoenixRetro/f256-superbasic/commit/9bdd76331bedce6d030fb72bea9eeb5fde996e86))

### Bug fixes

- Correct else indentation in list output ([`5431177`](https://github.com/FoenixRetro/f256-superbasic/commit/543117733b6873755b443f77041c70d9502366a9))
- Sprite collision threshold corrupted at high y-positions ([`a6a98b5`](https://github.com/FoenixRetro/f256-superbasic/commit/a6a98b5bbd66fca4612531cc9e5af798db8c5186))
- SPC() infinite loop and direct command loop after break ([`138f92c`](https://github.com/FoenixRetro/f256-superbasic/commit/138f92c08fea3ef013c53dbdb62ea3c919fdb1c5))
- Scroll navigation page boundary, indentation, and scroll-down ([`1a61878`](https://github.com/FoenixRetro/f256-superbasic/commit/1a61878b628d46ab6257236240a4ca946ea88725))
- Set FirstFreePage to 48 for 512KB systems ([`6e22acb`](https://github.com/FoenixRetro/f256-superbasic/commit/6e22acb1b14f7856a99f97e950ecee7a30756962))
- Inline string corruption in multi-page programs ([#113](https://github.com/FoenixRetro/f256-superbasic/issues/113)) ([`090cdae`](https://github.com/FoenixRetro/f256-superbasic/commit/090cdae5f498e5311e2ab40d80f96e0d1a4041bb))
- Tiles off command causes system lockup ([#93](https://github.com/FoenixRetro/f256-superbasic/issues/93)) ([`bea4257`](https://github.com/FoenixRetro/f256-superbasic/commit/bea42573b7b4c035356bcb1db7d393c1abb03c81))
- Slot 5 re-entrancy bug in `/` command and remove unused SIZE keyword ([#120](https://github.com/FoenixRetro/f256-superbasic/issues/120)) ([`f537d6b`](https://github.com/FoenixRetro/f256-superbasic/commit/f537d6bd0209d56085be2aabf363e3b3510d3945))
- DIR compatibility with older kernels, SAVE message and code section relief ([#142](https://github.com/FoenixRetro/f256-superbasic/issues/142)) ([`4974134`](https://github.com/FoenixRetro/f256-superbasic/commit/4974134def264fe18ba29e5ae862c2b4ee7ff78d))
- DIM a(255) zero-element array and scroll-up off-by-one fill ([#143](https://github.com/FoenixRetro/f256-superbasic/issues/143)) ([`440e373`](https://github.com/FoenixRetro/f256-superbasic/commit/440e37300694b29e8e8d915ee918910c1d66c504))
- Default text colour is grey instead of brown ([#144](https://github.com/FoenixRetro/f256-superbasic/issues/144)) ([`9924166`](https://github.com/FoenixRetro/f256-superbasic/commit/99241664cf51835ccae42c6b607deabd25ca77a5))
- Relieve code overflow that crashed string operations ([#145](https://github.com/FoenixRetro/f256-superbasic/issues/145)) ([`31ad261`](https://github.com/FoenixRetro/f256-superbasic/commit/31ad261f6599dc20b6ee38d840ba323c71acbbb0))
- Default text colour uses palette index 9 ($92) ([#146](https://github.com/FoenixRetro/f256-superbasic/issues/146)) ([`4c0edaf`](https://github.com/FoenixRetro/f256-superbasic/commit/4c0edafaed8d122b39aad6326423c51c0d674d7a))

### Under the hood

- Always clean `modules` build output ([`b747547`](https://github.com/FoenixRetro/f256-superbasic/commit/b747547f36b0ebedc953c505fab6ac063f3a08de))
- Bump minor version ([`7d636fa`](https://github.com/FoenixRetro/f256-superbasic/commit/7d636fac68f1efc9de0efba063d1aba4dcbadb63))
- Convert jmp to bra and remove redundant .cresync calls ([`763b150`](https://github.com/FoenixRetro/f256-superbasic/commit/763b150365df27a0be234b884e6316e487ecfafe))
- Fix memory allocation and build configuration ([`7620da4`](https://github.com/FoenixRetro/f256-superbasic/commit/7620da422fd30b07a81e3d3c6e3efb2a0d4e81f2))
- Remove Makefile emu target changes (testing only) ([`ba835c5`](https://github.com/FoenixRetro/f256-superbasic/commit/ba835c54690bdd8b1b40291b8c0c973afc197582))
- Document `ScanForward` etc ([`fab3210`](https://github.com/FoenixRetro/f256-superbasic/commit/fab3210bea39d8b5a5661c968c4418be4b0a4bd8))
- Document `VariableHandler` ([`6a8528e`](https://github.com/FoenixRetro/f256-superbasic/commit/6a8528e57ab11798169a38fe9601b26dfbb12855))
- Document `for`/`next` loop implementation ([`befdb16`](https://github.com/FoenixRetro/f256-superbasic/commit/befdb1679c65af39067467486109ad8a57635469))
- Update README links etc. ([`b48dbed`](https://github.com/FoenixRetro/f256-superbasic/commit/b48dbed3d8a3dfbd8bc4b347563327cbb9007ac0))
- Detect page overflows ([#132](https://github.com/FoenixRetro/f256-superbasic/issues/132)) ([`416e2fb`](https://github.com/FoenixRetro/f256-superbasic/commit/416e2fbe6a2f466a050f84d8903b9cd0574c85fc))
- Move `modules` dir under `source` ([#133](https://github.com/FoenixRetro/f256-superbasic/issues/133)) ([`3f15b28`](https://github.com/FoenixRetro/f256-superbasic/commit/3f15b285f67a98d0c69e23b931d3f9b30c975b31))
- Move `common.make` from `documents` to `source` ([#134](https://github.com/FoenixRetro/f256-superbasic/issues/134)) ([`1098b25`](https://github.com/FoenixRetro/f256-superbasic/commit/1098b25be718907b3165d053c1d7b1b98381cf2b))
- Delete obsolete `documents/fpga` dir ([#135](https://github.com/FoenixRetro/f256-superbasic/issues/135)) ([`061b1ae`](https://github.com/FoenixRetro/f256-superbasic/commit/061b1aee03d21998828778b5557aa7b2ffc2c3af))
- Move `benchmarks` dir to the root ([#136](https://github.com/FoenixRetro/f256-superbasic/issues/136)) ([`171218f`](https://github.com/FoenixRetro/f256-superbasic/commit/171218f663494d7bf0dd3406336ccc4676072210))
- Move Sublime syntax highlighting definition to `syntax` ([#137](https://github.com/FoenixRetro/f256-superbasic/issues/137)) ([`8f81c1e`](https://github.com/FoenixRetro/f256-superbasic/commit/8f81c1e40d5fc3e8aff5207edb555ea5257ce4e7))
- Add data overflow checks ([#139](https://github.com/FoenixRetro/f256-superbasic/issues/139)) ([`c2eb26a`](https://github.com/FoenixRetro/f256-superbasic/commit/c2eb26a91b4c47838fb8767ec22c35a74e102837))
- `common.make` -> `definitions.mk` ([#140](https://github.com/FoenixRetro/f256-superbasic/issues/140)) ([`2496ae7`](https://github.com/FoenixRetro/f256-superbasic/commit/2496ae7e427bc29c71228bc6649b862d06c7a915))
- Reserve top 4 physical pages for the NMI break monitor ([#147](https://github.com/FoenixRetro/f256-superbasic/issues/147)) ([`74434e7`](https://github.com/FoenixRetro/f256-superbasic/commit/74434e7c6d7da74a3e4f827adae37e87791d51d0))
- `uv` subproject, replace `mermaid` with `mermaidx` ([#148](https://github.com/FoenixRetro/f256-superbasic/issues/148)) ([`6196159`](https://github.com/FoenixRetro/f256-superbasic/commit/6196159a7507ceb4377fb536a83ed8710f226d53))
- Fix docs CI workflow ([#149](https://github.com/FoenixRetro/f256-superbasic/issues/149)) ([`3548407`](https://github.com/FoenixRetro/f256-superbasic/commit/3548407f914214da5b884437c8af5be543cb4991))

## v1.1.2025-10-06 - 2025-10-07

### Features

- `at` modifier for `print` ([`5bd1cf7`](https://github.com/FoenixRetro/f256-superbasic/commit/5bd1cf7a900e8717b1adb75df3ccea221976698b))
- `screen`/`screen$` support ([`b72c90a`](https://github.com/FoenixRetro/f256-superbasic/commit/b72c90a9b576bd7e2d0456eb1d7f6069c4f278d7))
- Display 2x core status on bootscreens ([`feed0e8`](https://github.com/FoenixRetro/f256-superbasic/commit/feed0e8e17615325ab0ca0d20d4427daac089242))

### Bug fixes

- Have DIR return normally, not breaking program flow, and report free blocks ([`2b7bd5c`](https://github.com/FoenixRetro/f256-superbasic/commit/2b7bd5c112f1ffab43b30745265935ec177593d2))
- `print at 59, 79; "*";` scrolls up the screen ([`ab9e000`](https://github.com/FoenixRetro/f256-superbasic/commit/ab9e000b1d88313a5cfbbf06a52aa81947dc3996))
- [**BREAKING**] Remove apostrophe-as-line-separator feature ([`54aa8e9`](https://github.com/FoenixRetro/f256-superbasic/commit/54aa8e982496664cb8ce5ca6ab545810f07f09b4))

### Performance

- Speedup disc operations ([`6cf6ce1`](https://github.com/FoenixRetro/f256-superbasic/commit/6cf6ce1a3a6730ebbbd08e75d0f40df6c83b3040))

### Under the hood

- README fixes, MAME testing instructions ([`1c43a28`](https://github.com/FoenixRetro/f256-superbasic/commit/1c43a289f675d8a896b1d961d731d6f13ceed8da))
- Automate module exports, remove temp build artifacts ([`730a55f`](https://github.com/FoenixRetro/f256-superbasic/commit/730a55f3b17e3353a8fa3afa3ec4b007473c336f))
- Comment up various `print`-related routines ([`142d33d`](https://github.com/FoenixRetro/f256-superbasic/commit/142d33d3ad277f68ae3653433737a8492c15f48e))
- Enable line ending normalization ([`c21ae79`](https://github.com/FoenixRetro/f256-superbasic/commit/c21ae7969b28cedaec8b829a5d52aa3ae68a9dac))
- Support for gen 2 builds ([`78e6ad2`](https://github.com/FoenixRetro/f256-superbasic/commit/78e6ad2b920ea65d6d69f91e4f6a7bf4c6cb51e0))
- Bring build/release Makefiles up-to-date with repo changes etc. ([`55b78c5`](https://github.com/FoenixRetro/f256-superbasic/commit/55b78c51e5299f1774b46cb5b7b8114b257a89ba))
- "Prepare release PR" Github workflow ([`1d5cd79`](https://github.com/FoenixRetro/f256-superbasic/commit/1d5cd796d6b9375e894d5f83e2785300ff86b275))
- Rework build & release procedure + repository cleanup ([`f6736ca`](https://github.com/FoenixRetro/f256-superbasic/commit/f6736ca1b0cc4a1e38b8da406cd38a3eeedd30d4))
- Add Contributing section ([`f2d07a7`](https://github.com/FoenixRetro/f256-superbasic/commit/f2d07a7979be463bfc383b07cb93b811a33a19c9))
- Support variable-height boostscreen rendering ([`b1c38a1`](https://github.com/FoenixRetro/f256-superbasic/commit/b1c38a18314984b03560c7dc1d6a6bf0bbd4b899))
- V1.1.2025-10-06 ([`2577337`](https://github.com/FoenixRetro/f256-superbasic/commit/25773372f522b6b2b7770bdd1d3345e059064ee1))


