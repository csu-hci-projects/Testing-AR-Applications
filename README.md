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
* Research will focus on automation of generating test cases, not automation of test execution
* Generation of test cases is based on depth-first traversal of 3D Objects
* Generation of tests assumes that an AR application is in a state where 3D objects are visible
* Similarly to 2D elements, each 3D object is considered a node in a tree where actions can be performed on the node
* Came up with basic method and steps for test case generation and will perform execuation manually:
   1. Manually Determine and setup preconditions for a scenario (number of visible objects, order in which they appear)
   2. Run depth-first traversal of nodes and perform actions (ex. select, translate, rotate, etc.) - application will have a test mode to automate this.  Method based on 2D GUI algorithms presented in references
   3. Log/Report generated test cases.
   4. Return to precondition state manually execute generated test cases.
  
## Checkpoint 4:

* Algorithm and reporting tools are complete for generating test cases - demo

Next Steps:

* Will begin experiments with hopes to use multiple scenarios, but test execution may be limited to a subset of generated test cases due to time limitations since test cases will need to be executed manually.
* Start the paper.
* Bonus - I hope to dive further into AI planning and search.  The current method I have implemented works well for small number of virtual objects, but AR enviornments with many objects will generate thousands or tens of thousands of possible test cases that may or may not be feasible.  AI planning and search can discover test cases that are valid and feasible.
