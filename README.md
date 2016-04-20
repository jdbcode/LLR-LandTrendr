# LLR-LandTrendr
LandTrendr (Landsat-based Detection of Trends in Disturbance and Recovery) algorimth modified to accept LandsatLinkr-processed imagery.

The Landsat satellites have witnessed decades of change on the Earth’s surface. Algorithms in LandTrendr (Landsat-based Detection of Trends in Disturbance and Recovery) attempt to capture, label, and map that change for use in science, natural resource management, and education.

LandTrendr is maintained by Robert Kennedy in the Geography group in the College of Earth, Ocean, and Atmospheric Sciences at Oregon State University, with recent contributions by David Miller, Jamie Perkins, Tara Larrue, Sam Pecoraro, and Bahareh Sanaie (Department of Earth and Environment, Boston University), and foundational contributions from Zhiqiang Yang and Justin Braaten in the Laboratory for Applications of Remote Sensing in Ecology located at Oregon State University and the USDA Forest Service’s Pacific Northwest Research Station.

This set of code allows images produced by the LandsatLinkr image processing system to easily be used as inputs. The Landtrendr algorimths remain the same, the alterations only deal with getting the LLR outputs hitched up as LT inputs.


Any use of this alorithm should give due credit:

Kennedy, Robert E., Yang, Zhiqiang, & Cohen, Warren B. (2010). Detecting trends in forest disturbance and recovery using yearly Landsat time series: 1. LandTrendr - Temporal segmentation algorithms. Remote Sensing of Environment, 114, 2897-2910

If it's critical to work you'll submit as a paper, please consider engaging Robert Kennedy as a co-author. If you make money from it, you need to develop an agreement with Oregon State University and Boston University.
Contact kennedyr@bu.edu for more on any of this."

# Instructions

**These instructions are a work in progress, please email me with any missing info that prevents running, or suggestions for clarification.**

### Downloading

Click on the "release" tab above and download the most recent version's .zip or .tar.gz source code. Decompress the code and place the code library somewhere that makes sense with your system of organization.

### Installing the IDL LandTrendr code

To run LandTrendr you need to have IDL on your system. Open an IDL session and use one of the many methods to source the library you just decompressed and stored. Generally, an easy way to accomplish this is to simply copy the whole code library and paste it into the "Default" project folder or create a new project and paste the code there.

### Running LandTrendr segmentation and fitting procedure

To run the LandTrendr segmentation and fitting procedure using outputs from the jdbcode/LandsatLinkr (LLR) library you need to modify two files included in the code library. One is a segmentation parameter file and the other is a batch file. Before you can run anything, however, you need to have completed the "Composite imagery" step of LLR. See the [LLR user guide](http://landsatlinkr.jdbcode.com/guide.html#composite_outputs) section on composite outputs to familiarize yourself with the files and directories that you'll be needing to define in the batchfile.

When running the LLR composite imagery step you defined a folder where the composite images are place. In this folder are subfolders for each spectral index that was composited. Currently it will include "tca", "tcb", "tcg", "tcw" (tasseled cap brightness, greenness, wetness, and angle). You will define the full path to these directories when you fill out the batchfile.

You need to create a folder for LandTrendr outputs, you can put this where you like - I usually put it at the same level as the composite image folders mentioned just a couple lines up. I call it "lt_outputs" or "landtrendr".

Keep this folder open so you can copy two files into it. These files will come from the code library. Copy the "segmentation_parameters.txt" file found in the "parameter_files" directory - paste it in the folder you just made. Now open the "run_files" directory in the code library and copy the "run_llr_lt_seg_and_fit_batchfile.pro" into the folder you just made.

Open the copied/pasted "segmentation_parameters" in a text editor (Notepad++ is a good). You need to edit the "run_name" and "base_index" parameters. The "run_name" is a unique identifier that will be added to the output filenames - just a descriptor to help keep your outputs organized - ie is this for a specific project you are working on. The "base_index" parameter tells the segmentation and fitting procedures what the spectral index it is that you are running so it know how to interpret spectral trend direction. **It is really important that it is defined strictly as either: brightness, greenness, wetness, or tcangle - whichever you happen to be running**. The other parameters affect the segmentation algorithms and can be set as you like, though the defaults are generally appropriate. For more information see Robert Kennedy's [paper](http://landtrendr.forestry.oregonstate.edu/sites/default/files/Kennedy_etal2010.pdf) describing the method or his [instructions](https://github.com/KennedyResearch/LandTrendr-2012/blob/master/docs/LandTrendr%20Users%20Guide.docx) on github. Save the file.

The last step is to edit the batchfile. Open the copied/pasted "run_llr_lt_seg_and_fit_batchfile.pro" file in IDL. There are 6 parameters.

*   **llr_composite_dir**: provide the full path to the llr composite image index directory you want to run LandTrendr on. It should be the same index you just defined in the "segmentation_parameters" file. Example: "K:\test\composite\tca\" - make sure the "\" character is at the end of the path.
*   **lt_output_dir**: full path to the LandTrendr outputs directory you just made and copied the "segmentation_parameters" and "run_llr_lt_seg_and_fit_batchfile.pro" files to. Example: "K:\test\composite\landtrendr\" - make sure the "\" character is at the end of the path.
*   **seg_params_txt**: full path to the "segmentation_parameters" file you just edited. Make sure that the in "base_index" parameter you set in it corresponds to the "llr_composite_dir" path you just set. Example: "K:\test\composite\landtrendr\tca_segmentation_parameters.txt"
*   **mask_image**: full path to a region of interest file that defines what pixel LandTrendr should be run on. It should be a .bsq raster file that contains only values 1 and 0. 1 for pixels to run LandTrendr on and 0 to ignore. This file can be the same file you provided to the LLR compositing function. However, you may need to convert it to a .bsq file - gdal can be helpful here, I will add a function to the LLR library as well. Example:"K:\test\composite\useareafile.bsq"
*   **eval**: a logical parameter for setting whether to run LandTrendr in evaluation mode (run every 3rd pixel and interpolate the rest) or full. 0 for full, 1 for evaluation.
*   **resume**: a logical parameter for resuming a LandTrendr run that has crashed because of a power or data transfer interruption. If this situation occurs, set resume to 1 and the process should continue where it was just before being interrupted. Leave set a 0 otherwise.

When you have finished editing the batchfile, save it and in the IDL command prompt type the @ symbol followed by the full path to the "run_llr_lt_seg_and_fit_batchfile.pro" file you just edited enclosed in quotes and hit enter. Example: @"K:\test\composite\landtrendr\tca_run_llr_lt_seg_and_fit_batchfile.pro"

IDL should be cranking away and a progress bar should be reporting its status. Files should be generated in a spectral index subfolder of the LandTrendr outputs folder you defined. You need to repeat the above steps for all spectral indices you want processed with LandTrendr. I use the same LandTrendr folder and just make new copies of the "segmentation_parameters.txt" and "run_llr_lt_seg_and_fit_batchfile.pro" files with unique spectral indices appended to the file names.


### Running LandTrendr change label and filtering procedure - NOT COMPLETE YET 4/20/16
*modified from Robert Kennedy's [instructions](https://github.com/KennedyResearch/LandTrendr-2012/blob/master/docs/LandTrendr%20Users%20Guide.docx)* 

In the prior step, the LandTrendr segmentation algorithm identified periods of time when spectral trajectories were consistently going "up", "down", or "stable", resulting in segments with vertices and fitted values to be viewed. However, such information is difficult to interpret or summarize in a simple fashion. To make these data more interpretable, in this step we categorize the segments into "change classes" based on their direction and magnitude of change, time of occurrence, and duration.  

For example, we are often interested in capturing disturbance events such as fires or landslides. To determine whether a given pixel might be in this class, we define a class whose spectral change "looks like" a disturbance that occurs quickly, and is of high magnitude. We may also be interested in limiting this to events that have occurred only recently, say after the year 2000. Capturing such phenomena of interest is the critical process of defining the rules used to map pixels into change classes.  We call this "change labeling".

Change labeling and spatial filtering is achieved by running an IDL batchfile provided with the code library. The batchfile requires 3 types of inputs:

1. A "*diag.sav" file path that provides information about the spectral segmentation and fitting run completed in previous step
2. A set of parameters that defines how thresholds will be applied to each segment of the fitted spectral files
3. A list of change classes
4. (optional) A cover model that converts specrtal values to percent vegetative cover

The label parameter file defines how thresholds will be applied to each segment, before it is evaluated for class code matching.  

The threshold is evaluated by comparing the starting and ending point of the segment.  

Typically, we convert the original spectral values to a converted index related to vegetative cover.  This has pros and cons. Changes can be expressed in terms that have some physical meaning, and by providing a concept for the value zero, relative change can be calculated in a meaningful way.  However, the calculation of a derived vegetative cover index requires good reference data, and even in the best case is often a noisy relationship with any single spectral index. Thus, the conversion to vegetative cover can introduce error.  

Note that the cover model must be built to match the index used for segmentation:  If NBR is used for segmentation, the cover model used for labeling must link NBR to a percent cover number.  

We provide two options with the code in the “paramfiles” folder:  an nbr_label_parameters.txt file that references a cover model, and an nbr_label_parameters_nocover.txt file that references a model that does not convert to percent cover – it leaves the spectral values as they were originally calculated. 

Temporal segments are defined as either "vegetative loss" or "vegetative gain" based on the index.

**Change labeling Parameters**

label parameter components:

static_model         = "static_nbr_model_pilot_scenes"  
change_model         = "none"  
pct_tree_loss1       = 10  
pct_tree_loss20      = 3  
pre_dist_cover       = 20  
pct_tree_gain        = 5  
collapse_dist_angle  = 15  
collapse_recv_angle  = 15  
run_name             = "nbr_lt_labels"  
merge_recovery       = "yes"  
extract_tc_ftv       = "yes"  
use_relative_mag     = "yes"  
end_year             = -1  
start_year           = -1

where:

**static_model**:  the name of a function that will return a percent cover estimate when fed a spectral index. See “static_nbr_model_pilot_scenes.pro” in the “cover_models” directory for an example.  The “static” means that the percent cover is modeled for each point in time, and then change in percent cover calculated by subtracting the modeled before and after values.   

**change_model**:  Currently not active.  We used this once when modeling only the change in percent cover from the change in the spectral index – i.e. subtract the index before and after, and use the difference value to model the change in percent cover.  

**pct_tree_loss1**:   the minimum percent cover loss for 1-year duration disturbance events.  Any disturbance segments with a smaller change are considered “no-change”, not disturbance.  

**pct_tree_loss20**:   the minimum percent cover loss for 20-year duration disturbance processes.  This is typically lower than the 1-year duration value.  If a decline is going on for 20 years and statistically sound, then it’s pretty unlikely it’s caused by noise.  But a 1-year spike could be caused by noise, so we want the threshold for change to be higher for the 1-year event.   We interpolate the percent cover threshold linearly between the two values. 

**pre_dist_cover**:   The minimum percent cover estimated before the change.  If a disturbance occurs in an area with less cover than this value, it’s considered noise.  For very sparse systems, you may want to move this value very low.

**pct_tree_gain**:  The minimum cover gain needed to call a segment growth. 

All of the prior cover estimates are based on the model you provide.  If you don’t have a statistical and simply use the “nocover” model procedure, then the units of the parameters above are not percent cover, but whatever index you use.  Keep that in mind – you’ll probably want to change the values!  

**collapse_dist_angle**:
**collapse_recv_angle**:
These parameters refer to how LT handles two successive segments of the same type.  If two recovery segments occur in sequence and indicate roughly the same rate of recovery, you may not really want to consider them separate segments.  If they are quite different rates, though, you might want to keep them separate.  This angle allows you to set the value LT uses to merge two segments together – if the angle between the two segments is less than the number you provide, and if you set the “merge_recovery” to “yes”, then recovery segments that are similar will be merged. 

But how do we get an angle? The segments are constructed in a spectral space by years data space, so an angle in the original space doesn’t make sense. Rather, we scale each trajectory on the X and Y axis to make a square plot, and calculate the angle in this stretched space. It’s analogous to what you’d do visually if you  were plotting the trajectory.  But you’re right – it’s going to be different for each trajectory.   

**run_name**:  Critical! This name is used to create sub-directory in the outputs/<spectral_index> directory.  Make sure it’s what you want. 

**merge_recovery**: see “collapse dist_angle” and “collapse_recv_angle.”

**extract_tc_ftv**: Recommended! When the labeling phase is done, this will create the ftv_context images that describe the tasseled-cap condition of the site before, during, and after the change.  

**use_relative_mag**: If set to "yes", then all of the thresholds above are interpreted as relative change – the percent cover before and after is calculated, and the difference divided by the cover before the change.  This really only makes sense to use if you are using an actual cover model, since only then does the range from zero to 100% work. 




**Change Class Codes** 
Class codes are the rules used to define interesting patterns in each pixel's fitted trajectory.  For example, you can create a class code that finds all disturbances greater than a particular magnitude. The syntax for the class codes is flexible, but generically useful classes have been pre-determined (in the batchfile). If you want a different class the following section defines the class code syntax.

Here is an example of a class code:   
5#greatest_fast_disturbance#Y#GDXX0000L04X00

The class code is a string with several pieces of information in it separated by the "#" sign.  Essentially, the way to think of the code is: "Class 5 is called Greatest Fast Disturbance.  For a pixel to be in this class, it must meet the criteria I describe here". The left-hand portion of the code describes the class identifier names and code, while the right-hand portion describes the rules that would be needed for a pixel to be placed in that class.

The rules for the class follow a strict syntax and use a limited set of codes. 

The rule syntax is as follows:  

**C#className#T#RRLLYYYYDUUPWW**

where:

**C**: numerical class value

**className**: the name applied to the output file

**T**: turn the class on or off
  * **Y**: yes, turn on
  * **N**: no, turn on

**RR**: change pixel type rule
  * **FD**: first disturbance
  * **RD**: recent disturbance
  * **GD**: greatest disturbance
  * **SD**: second greatest disturbance
  * **LD**: longest distrubance
  * **FR**: first recovery
  * **RR**: recent recovery
  * **GR**: greatest recovery
  * **SR**: second greatest recovery
  * **LR**: longest recovery
  * **XX**: no rule
 
**LL**: year if onset rule  
  * **EQ**: equal to
  * **LE**: less than or equal to
  * **GE**: greater than of equal to
  * **XX**: no rule

**D**: duration rule
  * **G**: greater than
  * **L**: less than
  * **X**: no rule
   
**UU**: duration in years for which the above rule will be applied

**P**: pre-disturbance rule
  * **G**: greater than
  * **L**: less than
  * **X**: no rule

**WW**: pre-disturbance cover value for which the above pre-disturbance cover rule applied

Following these rules, the class given above (‘5#greatest_fast_disturbance#Y#GDXX0000L04X00’) would be interpreted as follows for each pixel:  

GD:  Find disturbance segments (based on the index being used – see discussion at the beginning of this section on how we define disturbance).  If there is more than one disturbance segment for this pixel, then pick the one with the greatest change (based on beginning and end of the segment). 
XX0000:  No restriction on when the disturbance is allowed to happen – a disturbance happening at any point is fair game.  You could set this to GE1995, for example, to only find disturbances that happen in 1995 or later.  
L04:  Only include disturbance segments that have duration less than or equal to 4 years. 
X00:  Do not apply a class-specific pre-disturbance percent cover threshold.  There is an overall pre-event percent cover rule specified in the 

Another example:  
Say you want a class that records only the greatest disturbances after the year 1998, you want them to be only fast disturbances that are less than or equal to 4 years in duration, and only in dense cover.  Look back at the table above to see how the codes relate to the steps below.
‘C#<class_name>#T#RRLLYYYYDUUPWW#placeholder(RRLLYYYYDUUPWW)’

C = 9 (arbitrary, but don’t use 0, 1 ,2 or overwrite other existing class numbers)
Class name = greatest_fast_dist_post_1998
T = Y		
RR = GD
LL = GE
YYYY = 1999
D = L
UU = 04
P = G
WW = 50

Thus, putting all these together we get:  ‘9#greatest_fast_dist_post_1998#Y#GDGE1999L04G50# XXXX0000X00X00’

