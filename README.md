#  CS567 Final Project - ~~Testing AR Applications~~ Systematic Test Case Generation For Augmented Reality Applications

## Checkpoint 1 updates:

* Scratched ~~Unreal~~ in favor of Xcode/ARKit because Unreal seems to run really slow on my Mac
* ARKit has handy plane detection tools and detects vertical planes which will be useful
* Created a basic application that detects and visualizes vertical planes
* Researched multiple computer vision techniques:
    * https://www.ipol.im/pub/art/2018/229/ - a paper and online demo of harris corner detection - looks useful but generates a lot of noise, possibly combine this with plane intersections could reduce the noise
    * Apple developer documentation on tracking and visualizing planes: https://developer.apple.com/documentation/arkit/tracking_and_visualizing_planes
    * "Simultaneous Localization
    and Map-Building Using Active Vision" https://pdfs.semanticscholar.org/c63c/d5da01e5abbb3892821016bbc5a9825fcf44.pdf - seems like novel techniques but applies to indoors, looking for more specifics on exterior walls of buildings.
* Next step
    * relearn plane geometry/math and figure out how to find the intersection of two planes and complete the application
    * work on proposal for CS514 - research test generation techniques to apply to 3D UI

## Checkpoint 2:

* Completed development of intersecting two planes - some minor changes needed, but application is mostly complete
* Submitted proposal for CS514 and came up with research question -> [pdf](https://github.com/csu-hci-projects/Testing-AR-Applications/blob/master/CS514_PROPOSAL.pdf)

## Checkpoint 3:

* Revised proposal for CS514 with new title - **Systematic Test Case Generation For Augmented Reality Applications**
* More to come by friday...
