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

**These instructions are a work in progress please, email me with any missing info that prevents running or suggestions for clarification.**

### Downloading

Click on the "release" tab above and download the most recent version's .zip or .tar.gz source code. decompress the code and place the code library somewhere that makes sense with your system of organization.

### Installing the IDL LandTrendr code

To run LandTrendr you need to have IDL on your system. Open an IDL session and use one of the many methods to source the library you just decompressed and stored. Generally, an easy way to accomplish this is to simply copy the whole code library and paste it into the "Default" project folder or create a new project and paste the code there.

### Running LandTrendr segmentation and fitting procedure

To run the LandTrendr segmentation and fitting procedure using outputs from the jdbcode/LandsatLinkr (LLR) library you need to modify two files included in the code library. One is a segmentation parameter file and the other is a batch file. Before you can run anything, however, you need to have completed the "Composite imagery" step of LLR. See the [LLR user guide](http://landsatlinkr.jdbcode.com/guide.html#composite_outputs) section on composite outputs to familiarize yourself with the files and directories that you'll be needing to define in the batchfile.

When running the LLR composite imagery step you defined a folder where the composite images are place. In this folder are subfolders for each spectral index that was composited. Currently it will include "tca", "tcb", "tcg", "tcw" (tasseled cap brightness, greenness, wetness, and angle). You will define the full path to these directories when you fill out the batchfile.

You need to create a folder for LandTrendr outputs, you can put this where you like - I usually put it at the same level as the composite image folders mentioned just a couple lines up. I call it "lt_outputs" or "landtrendr".

Keep this folder open so you can copy two files into it. These files will come from the code library. Copy the "segmentation_parameters.txt" file found in the "parameter_files" directory - paste it in the folder you just made. Now open the "run_files" directory in the code library and copy the "run_llr_lt_seg_and_fit_batchfile.pro" into the folder you just made.

Open the copied/pasted "segmentation_parameters" in a text editor (Notepad++ is a good). You need to edit the "run_name" and "base_index" parameters. The "run_name" is a unique identifier that will be added to the output filenames - just a descriptor to help keep your outputs organized - ie is this for a specific project you are working on. The "base_index" parameter tells the segmentation and fitting procedures what the spectral index it is that you are running so it know how to interpret spectral trend direction. **It is really important that it is defined strictly as either "brightness", "greenness", "wetness", or "tcangle" - whichever you happen to be running**. The other parameters affect the segmentation algorithms and can be set as you like, though the defaults are generally appropriate. For more information see Robert Kennedy's [paper](http://landtrendr.forestry.oregonstate.edu/sites/default/files/Kennedy_etal2010.pdf) describing the method or his [instructions](https://github.com/KennedyResearch/LandTrendr-2012/blob/master/docs/LandTrendr%20Users%20Guide.docx) on github. Save the file.

The last step is to edit the batchfile. Open the copied/pasted "run_llr_lt_seg_and_fit_batchfile.pro" file in IDL. There are 6 parameters.

*   **llr_composite_dir**: provide the full path to the llr composite image index directory you want to run LandTrendr on. It should be the same index you just defined in the "segmentation_parameters" file. Example: "K:\test\composite\tca\" - make sure the "\" character is at the end of the path.
*   **lt_output_dir**: full path to the LandTrendr outputs directory you just made and copied the "segmentation_parameters" and "run_llr_lt_seg_and_fit_batchfile.pro" files to. Example: "K:\test\composite\landtrendr\" - make sure the "\" character is at the end of the path.
*   **seg_params_txt**: full path to the "segmentation_parameters" file you just edited. Make sure that the in "base_index" parameter you set in it corresponds to the "llr_composite_dir" path you just set. Example: "K:\test\composite\landtrendr\tca_segmentation_parameters.txt"
*   **mask_image**: full path to a region of interest file that defines what pixel LandTrendr should be run on. It should be a .bsq raster file that contains only values 1 and 0. 1 for pixels to run LandTrendr on and 0 to ignore. This file can be the same file you provided to the LLR compositing function. However, you may need to convert it to a .bsq file - gdal can be helpful here, I will add a function to the LLR library as well. Example:"K:\test\composite\useareafile.bsq"
*   **eval**: a logical parameter for setting whether to run LandTrendr in evaluation mode (run every 3rd pixel and interpolate the rest) or full. 0 for full, 1 for evaluation.
*   **resume**: a logical parameter for resuming a LandTrendr run that has crashed because of a power or data transfer interruption. If this situation occurs, set resume to 1 and the process should continue where it was just before being interrupted. Leave set a 0 otherwise.

When you have finished editing the batchfile, save it and in the IDL command prompt type the @ symbol followed by the full path to the "run_llr_lt_seg_and_fit_batchfile.pro" file you just edited enclosed in quotes and hit enter. Example: @"K:\test\composite\landtrendr\tca_run_llr_lt_seg_and_fit_batchfile.pro"

IDL should be cranking away and a progress bar should be reporting its status. Files should be generated in a spectral index subfolder of the LandTrendr outputs folder you defined. You need to repeat the above steps for all spectral indices you want processed with LandTrendr. I use the same LandTrendr folder and just make new copies of the "segmentation_parameters.txt" and "run_llr_lt_seg_and_fit_batchfile.pro" files with unique spectral indices appended to the file names.
