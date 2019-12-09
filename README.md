#  CS567 Final Project - Systematic Test Case Generation For Augmented Reality Applications

**Abstract:** Augmented Reality (AR) is a type of software that superimposes virtual objects into the physical world.  The reliance that AR has on the physical world makes AR applications difficult to test and very little research exists in the area of testing AR applications.  The objective of this paper is to evaluate if traditional techniques used for test generation on 2D graphical user interfaces (GUI) can be applied effectively to AR applications.  We have developed a systematic method that expands on known techniques in test generation and test automation on traditional 2D GUIs and applies them to 3D objects in an AR environment.  The focus of our research is on test generation but we also demonstrate a method that applies both automated and manual steps to create an end to end test solution for AR applications that can be generalized for most AR applications.  The method is demonstrated on a case study of an AR application that has been developed that detects and measures walls of physical structures such as condo buildings, and commercial buildings.  Given multiple scenarios presented for different structures, we were able to generate a total of 42,840 feasible test cases and through manual execution of 30 test cases, discovered a total of 22 faults.  Based on our results we have found that using existing GUI techniques for test generation applied to our method can be effective.  Although our method has been found to be effective, further research and more case studies are recommended for validating our method and to develop more robust methods that can automate the testing process for AR applications.

## Running

This project requires MacOS and iOS hardware and software to run.  A typically MacBook running XCode should suffice for development, and at least an iPhone that supports the requirements for ARKit is required to run the application.

More Info:
* XCode: [https://developer.apple.com/xcode/](https://developer.apple.com/xcode/)
* ARKit: [https://developer.apple.com/augmented-reality/](https://developer.apple.com/augmented-reality/)


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

## Checkpoint 5:

* Results collected - [results](results/)
* Paper draft complete - [paper_draft1](paper_draft1.pdf)
* CS514 Poster complete - [rlafranc_poster](rlafranc_poster.pdf)
* Website Complete (minus demo video) - [website](https://www.cs.colostate.edu/~rlafranc/#/cs-567-project)

## Checkpoint 6:

* Project complete and submitted
