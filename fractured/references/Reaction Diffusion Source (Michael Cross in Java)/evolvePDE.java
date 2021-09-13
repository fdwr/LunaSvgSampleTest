/*
 * @(#)evolvePDE.java  5/7/99
 *
 * Copyright (c) 1999, Michael Cross All Rights Reserved.
 *
 * Evolves coupled PDEs in 2 dimensions using finite difference or pseudo-spectral method
 * Compatible with Java 1.0.
*/

import java.applet.Applet;
import java.awt.event.*;
import java.awt.*;
import java.awt.image.ColorModel;
import java.awt.image.MemoryImageSource;
import java.lang.InterruptedException;
import java.io.*;
import java.net.*;

// import java.lang.*;       //Needed for application not applet

public class evolvePDE extends Applet implements Runnable {

      private static final int CGL=0;
      private static final int BRUSSELATOR=1;
      private static final int SCHNACKENBERG=2;
      private static final int SH=3;
      private static final int BARKLEY=4;      
      private static final int BAR=5;
      private static final int LIFSHITZ=6;
      private static final int SH2=7;
      private static final int FHN=8;
            
      

    //Declare variables and classes
    ThreadGroup appletThreadGroup;
    Thread runner;

    plotControls plotControls;        // User interface
    Label minLabel, maxLabel;
    textControls parameterControls;
    plotChoiceControls plotChoice;
    
    plotCanvas canvas;                // Plotting region
    PDE myPDE;                        // PDE evolver
    myPallette myPal;                 // Pallette for plotting
         
    double[][][] psi;                 // Fields for evolving
    double[][][] psir;                // Fields for plotting
    int[]   pixels;                   // Pixels fed to plotter
    MemoryImageSource source;
    Image image;      
    
    double vals[] = new double[1];    // Values read from plotControls
           
    // Parameters: most are reset from html file
    int width;                      // Dimensions of array for evolving - must be
    int height;                     // power of 2 for spectral code
    int plotwidth;                  // Dimensions of array for plotting - must equal
    int plotheight;                 // width, height for finite difference code.
    int scalex;                     // Ratio of plotwidth to width
    int scaley;                     // Ratio of plotheight to height
    int plotType;                   // Type of plot
    int oldPlotType;                // To see if type of plot changed
    int function;                   // Function type
    int fields;                     // Number of fields
    int palletteType;               // Pallette used
            
    double xmin;                    // Size
    double xmax;
    double ymin;
    double ymax;
    double mesh;                    // Mesh spacing
    double minimum;                 // User set minimum for plotting if not scaleMinMax
    double maximum;                 // User set maximum for plotting if not scaleMinMax
     
    double[] parameters;            // parameters of PDE
    int nParameters;
    
    double dt;                      // Time stepping
    double t=0;
    double steps=1.;                // Steps between plotting
    
    double[][] icp;                 // Parameters for initial condition
    int nicp;                       // Number of initial condition parameters
        
    // User input flags
    boolean scalePlot;              // If true plot scales with window
    boolean showTime;               // If true time is displayed
    boolean scaleMinMax;            // If true plots are scaled to min and max values
    boolean showMinMax;             // If true min and max values are shown
    boolean choosePlots;            // If true user may choose plot type
    boolean plotFFT;                // If true plots FFT for spectral code

    // Internal flag
    boolean runOnce=false;          // Set true after initial conditions plotted

    String file_in,file_out;        // Files for data read in and write out (set to
                                    // "none" for no file access).

    // Initialization method for applet
    public void init() {
    
        // Initialize function
        function=(new Integer(getFromApplet("function","0"))).intValue();

        switch (function) {
             case CGL:
                   myPDE = new CGL();
                   break;
             case BRUSSELATOR:
                   myPDE = new Brusselator();
                   break;                   
             case SCHNACKENBERG:
                   myPDE = new Schnackenberg();
                   break;                        
             case SH:
                   myPDE = new SH();
                   break;
             case BARKLEY:
                   myPDE = new Barkley();
                   break;
             case BAR:
                   myPDE = new Bar();
                   break;
             case LIFSHITZ:
                   myPDE = new Lifshitz();
                   break;
             case SH2:
                   myPDE = new SH2();
                   break;
             case FHN:
                   myPDE = new FHN();
                   break;                   
             default:
                   myPDE = new CGL();
                   break;
        }
        
        // Get parameters from html file
        nParameters=myPDE.nParameters;
        nicp=myPDE.nInitialParameters;        
        parameters=new double[nParameters];
        getAllParameters();
        oldPlotType=plotType;
        
        xmin=0.;
        xmax=width*mesh;
        ymin=0.;
        ymax=height*mesh;
                
        // Set pltting scale factors
        if(plotwidth<width) plotwidth=width;
        if(plotheight<height) plotheight=height;
        scalex=plotwidth/width;
        scaley=plotheight/height;
        myPDE.setScales(scalex,scaley);
        
        // Print out parameters to console
        System.out.println("dt ="+dt);
        for(int i=0;i<nParameters;i++)
            System.out.println("parameter"+i+" = "+parameters[i]);
        System.out.println("width ="+width+" height ="+height);
        System.out.println("plotwidth ="+plotwidth+" plotheight ="+plotheight);
        System.out.println("xmin ="+xmin+" xmax ="+xmax+" ymin ="+ymin+" ymax ="+ymax+" ");
                
        // Set up arrays
        fields=myPDE.fields;
        System.out.println("Number of fields= "+fields);
        icp=new double[fields][nicp];        
        for(int i=0;i<fields;i++) {
           for(int j=0;j<nicp;j++) {
              icp[i][j]=(new Double(getFromApplet("ic"+i+j,"0."))).doubleValue();            
              System.out.println("icp["+i+j+"]: "+icp[i][j]);
           }   
        }    
        psi = new double[fields][width+1][height+1];
        psir = new double[fields][plotwidth+1][plotheight+1];
        
// Set up image for animation. See
// http://www.javasoft.com/products/jdk/1.2/docs/api/java/awt/image/MemoryImageSource.html
        pixels = new int[plotwidth * plotheight];
        source=new MemoryImageSource(plotwidth, plotheight,
                  ColorModel.getRGBdefault(), pixels, 0, plotwidth);
        source.setAnimated(true);
        source.setFullBufferUpdates(true);
        image=createImage(source);        
        
        // Set up GUI
        setLayout(new BorderLayout());

        plotControls = new plotControls(this, steps, showTime);
        plotControls.addRenderButton();
        add("South", plotControls);
        if(showMinMax) {
            Panel topPanel = new Panel();
            topPanel.setLayout(new FlowLayout(FlowLayout.LEFT, 5, 5));
            minLabel = new Label("Min = -0.00000000",Label.LEFT);
            topPanel.add(minLabel);
            maxLabel = new Label("Max = 0.00000000",Label.LEFT);
            topPanel.add(maxLabel);
            add("North",topPanel);
        }

        Panel rightPanel = new Panel();
        GridBagLayout gridbag = new GridBagLayout();
        GridBagConstraints constraints = new GridBagConstraints();
        constraints.fill=GridBagConstraints.BOTH; 
        rightPanel.setLayout(gridbag);
        add("East",rightPanel);   

        String[] textboxes = new String[nParameters];
        for(int i=0;i<nParameters;i++)
                  textboxes[i]= String.valueOf(parameters[i]);        
        parameterControls = new textControls(textboxes,myPDE.labels,nParameters,5);

        constraints.gridwidth=1;
        constraints.weightx=1;
        constraints.gridwidth=GridBagConstraints.REMAINDER;
        constraints.weighty=4;        
        gridbag.setConstraints(parameterControls, constraints);
        rightPanel.add(parameterControls);                            

        if(choosePlots) {
            plotChoice=new plotChoiceControls(myPDE.numPlotTypes,myPDE.spectral);
            constraints.weighty=1;
            gridbag.setConstraints(plotChoice, constraints);                      
            rightPanel.add(plotChoice);
            plotChoice.setPlotType(plotType);        
            if(myPDE.spectral) plotChoice.setPlotFFT(plotFFT);
        }
       
        add("Center", canvas = new plotCanvas());
        if(!scalePlot) canvas.setSize(plotwidth,plotheight);        
        
        // Set up solver, and plotting
        myPDE.init(width, height,parameters,dt,mesh,plotType);
        if(palletteType!=0) myPDE.setPallette(palletteType);
        myPal = myPDE.getPallette();

        
      plotControls.getParams(vals);
      for(int i=0;i<nParameters;i++)
               parameters[i]=parameterControls.parseTextField(i,parameters[i]);
      myPDE.setParameters(nParameters,parameters);        

                
        // Set up initial conditions
        setInitialConditions();
       
        // Start thread for evolving
        appletThreadGroup = Thread.currentThread().getThreadGroup();      
    }

//************************************************************************
    public void destroy() {
        remove(plotControls);
        remove(canvas);
//      System.exit(0);              // Exit for application
    }

//************************************************************************
    public void start() {
        if(plotControls.reset) {
            setInitialConditions();
            runOnce=false;
            plotControls.reset=false;
        }  
        runner = new Thread(this);
        runner.start();
    }

//************************************************************************
    public void stop() {
      runner = null;
      plotControls.runAnimation=false;
      plotControls.setButtonLabel(" Start ");
    }
    
//************************************************************************
    // Main method is only used for application not applet
    public static void main(String args[]) {
      Frame f = new Frame("evolvePDE");
      evolvePDE  evolve = new evolvePDE();
      evolve.init();

      f.add("Center", evolve);
      f.pack();
      f.show();

      evolve.start();
    }
    
//************************************************************************
    public void run() {
        while(plotControls.runAnimation) {
//            Don't seem to need next line 5/27/99
//            canvas.setImage(null);            // Wipe previous image
              Image img = calculateImage();
              synchronized(this) {
                  if (img != null && runner == Thread.currentThread())
                      canvas.setImage(img);
              }
        }
        plotControls.setStart();       // Set plotControls ready to start again
        if((!file_out.equals("none")) & runOnce) writeout();
    }
  
//************************************************************************
/**
* Calculates and returns the image.  Halts the calculation and returns
* null if the Applet is stopped during the calculation.
*/
//************************************************************************    
    Image calculateImage() {

      int i,j,k,ist,count;

      // Update parameters from GUI
      plotControls.getParams(vals);
      count=(int)vals[0];
      for(i=0;i<nParameters;i++)
               parameters[i]=parameterControls.parseTextField(i,parameters[i]);
      myPDE.setParameters(nParameters,parameters);

      // Evolve equations if not i.c., otherwise get ready
      if(runOnce) {
           ist=0;
           while(ist++<count && plotControls.runAnimation) 
                  t=myPDE.tstep(psi,t);
      }
                  
      for(k=0;k<fields;k++) {
          // Interpolate into larger plot range
          if(plotwidth!=width || plotheight!=height)
            for (j = 1; j <= plotheight; j++)
              for (i = 1; i <= plotwidth; i++)
                   psir[k][i][j]=0.;

          for (j = 1; j <= height; j++) 
              for (i = 1; i <= width; i++) 
                   psir[k][i][j]=psi[k][i][j];
      }
      
      // Type of plot depends on function and user choice
      if(choosePlots) {
        plotType=plotChoice.getPlotType();
        myPDE.setPlotType(plotType);
        if(plotType!=oldPlotType) {
            myPDE.setPallette();
            myPal = myPDE.getPallette();
            oldPlotType=plotType;
        }
        if(plotChoice.getPlotFFT())
            myPDE.makeFFTPlot(psir,plotwidth,plotheight);
        else
            myPDE.makePlot(psir,plotwidth,plotheight);
      }
      else
         myPDE.makePlot(psir,plotwidth,plotheight);
      
      // Scale onto color plot
      scale(psir[0],pixels,plotwidth,plotheight); 
      if(showTime) plotControls.setTime("Time = "+String.valueOf((float) t));
           
      // If this is intial condition get ready to animate
      if(!runOnce) {
         plotControls.runAnimation=false;
         plotControls.buttonEnable();
         runOnce=true;
      }      

      // Poll once per frame to see if we've been told to stop.
      Thread me = Thread.currentThread();            
      if (runner != me) return null;

      source.newPixels();      
      return image;

//    (Changed 5/5/99). Before, made new image each update.
//    Replaced by making image in initialization and only updating here.
//    return createImage(new MemoryImageSource(plotwidth, plotheight,
//                ColorModel.getRGBdefault(), pixels, 0, plotwidth));

    }

//************************************************************************
/**    
* Calculates pixel map from field 
* @param data array of real space data
* @param pixels array of packed pixels
* @param nx number of pixels in x-direction
* @param ny number of pixels in y-direction
*/
//************************************************************************
    private void scale(double[][] data, int[] pixels, int nx, int ny) {
       double min;
       double max;
       double mult;
       int plotdata;
       int c[] = new int[4];
       int index = 0;
       int i,j;
       
       min=1000000.;
       max=-1000000.;
       if(scaleMinMax || showMinMax) {
           for(j=1;j<=ny;j++){
               for(i=1;i<=nx;i++) {
                   min = Math.min(min,data[i][j]);
                   max = Math.max(max,data[i][j]);
               }
           }
       }       
       if(showMinMax) {
           minLabel.setText("Min = "+String.valueOf((float) min));       
           maxLabel.setText("Max = "+String.valueOf((float) max)); 
       }
       if(!scaleMinMax) {
             min=minimum;
             max=maximum;
       }
                 
       mult=255./(max-min);
       
       for(j=1;j<=ny;j++) {
           for(i=1;i<=nx;i++){
                plotdata=(int)(mult*(data[i][j]-min));
                if(plotdata<0) plotdata=0;
                if(plotdata>255) plotdata=255;                
                c[0] = myPal.r[plotdata];
                c[1] = myPal.g[plotdata];
                c[2] = myPal.b[plotdata];
                c[3] = 255;
                pixels[index++] = ((c[3] << 24) |
                           (c[0] << 16) |
                           (c[1] << 8) |
                           (c[2] << 0));                
           }
       }       
    }
           
//************************************************************************       
/**
* Gets parameters from html file and sets default values
*/
//************************************************************************
    protected void getAllParameters() {
            width=(new Integer(getFromApplet("solvewidth","64"))).intValue();
            height=(new Integer(getFromApplet("solveheight","64"))).intValue();
            plotwidth=(new Integer(getFromApplet("plotwidth","64"))).intValue();            
            plotheight=(new Integer(getFromApplet("plotheight","64"))).intValue();
            choosePlots=false;
            if(getFromApplet("chooseplots","false").toLowerCase().equals("true"))
                  choosePlots=true;
            plotType=(new Integer(getFromApplet("plottype","0"))).intValue();
            plotFFT=false;
            if(getFromApplet("plotspectral","false").toLowerCase().equals("true"))
                  plotFFT=true;
            palletteType=(new Integer(getFromApplet("pallette","0"))).intValue();            
            steps=(new Double(getFromApplet("speed","1."))).doubleValue();            
            for(int i=0;i<nParameters;i++)
                 parameters[i]=(new Double(getFromApplet("parameter"+i,myPDE.defaultValues[i]))).doubleValue();
            dt=(new Double(getFromApplet("dt","0.1"))).doubleValue();
            mesh=(new Double(getFromApplet("mesh","1."))).doubleValue();
            scalePlot=false;
            if(getFromApplet("scaleplot","false").toLowerCase().equals("true"))
                  scalePlot=true;
            scaleMinMax=true;
            if(getFromApplet("scaleminmax","true").toLowerCase().equals("false"))
                  scaleMinMax=false;
            showMinMax=true;
            if(getFromApplet("showminmax","true").toLowerCase().equals("false"))
                  showMinMax=false;
            minimum=(new Double(getFromApplet("minimum","0."))).doubleValue();
            maximum=(new Double(getFromApplet("maximum","1."))).doubleValue();
            showTime=false;
            if(getFromApplet("showtime","false").toLowerCase().equals("true"))
                  showTime=true;            
            file_in=getFromApplet("filein","none").toLowerCase();
            System.out.println("Input_file "+file_in);
            file_out=getFromApplet("fileout","none").toLowerCase();

    }

//************************************************************************    
    protected String getFromApplet(String parameter, String s) {
        String getString = getParameter(parameter);
        if(getString == null) return s;
        else if(getString.length() == 0) return s;
        else return getString;
    } 
    
//************************************************************************    
    private void setInitialConditions() {
        t=0.;
        if(file_in.equals("none"))
            myPDE.initialCondition(psi, icp, nicp);
        else
            readin();
   }
//************************************************************************               
    public void readin() {
       double[] min;
       double[] max;
       
       double[] mult;
       double dummy;
       
       int i,j,k;             
       int in_width, in_height;

       min=new double[fields];
       max=new double[fields];       
       mult=new double[fields];
      try {
//      For local file
//      DataInputStream dis = new DataInputStream(
//                                     new FileInputStream(file_in));

//    For remote file
      URL documentBase=getCodeBase();
      URL inputFile = new URL(documentBase,file_in);
      URLConnection fc = inputFile.openConnection();
      DataInputStream dis = new DataInputStream(
                                     fc.getInputStream());                                     
      in_width=dis.readInt();
      in_height=dis.readInt();
      if(in_width==width & in_height==height) {
         for(k=0;k<fields;k++) {
            min[k]=dis.readDouble();
            max[k]=dis.readDouble();
            mult[k]=dis.readDouble();
            System.out.println("Field "+k+" min= "+min[k]+" max= "+max[k]+" mult= "+mult[k]);
         }
         for (i = 0; i < width+1; i ++) {
             for (j= 0; j< height+1; j++) {
                   for(k=0;k<fields;k++) {
//  If want more accurate write out and read in use writeDouble and then readDouble
//                      dummy= dis.readDouble();
                        dummy= (double)dis.readByte();
                        if(dummy<0) dummy=dummy+256;
                        psi[k][i][j]=min[k]+(dummy)/mult[k];
 
                   }                   
                }
            }
      }
      else
            System.out.println("In data file width = "+in_width+" height = "+in_height);
      dis.close();
      } catch (IOException e) {
              System.out.println("File IO error");
      }
                                                  
    }    
    
    // Only works for applet started locally from directory in CLASSPATH
    public void writeout() {
      
      double[] min;
      double[] max;
      
      double[] mult;
      byte outdata;
      int i,j,k;
      
      min=new double[fields];
      max=new double[fields];       
      mult=new double[fields];
      for(k=0;k<fields;k++) {
           min[k]=1000000.;
           max[k]=-1000000.;
      } 
      
      for(i=0;i<width+1;i++){
           for(j=0;j<height+1;j++) {
               for(k=0;k<fields;k++) {
                  min[k] = Math.min(min[k],psi[k][i][j]);
                  max[k] = Math.max(max[k],psi[k][i][j]);
               }  
           }
       } 

      for(k=0;k<fields;k++) {
          mult[k]=254.9/(max[k]-min[k]);
          System.out.println("Field "+k+" min= "+min[k]+" max= "+max[k]+" mult= "+mult[k]);
      }    

      try {
      DataOutputStream dos = new DataOutputStream(
                                     new FileOutputStream(file_out));

      dos.writeInt(width);
      dos.writeInt(height);
      for(k=0;k<fields;k++) {
         dos.writeDouble(min[k]);
         dos.writeDouble(max[k]);
         dos.writeDouble(mult[k]);
      }     
       for(i=0;i<width+1;i++){
            for(j=0;j<height+1;j++) {
                for(k=0;k<fields;k++) {                       
//    If want more accurate write out and read in use writeDouble and then readDouble
//                  dos.writeDouble((mult[k]*(psi[k][i][j]-min[k])));
                    dos.writeByte((byte)Math.rint(mult[k]*(psi[k][i][j]-min[k])));
                }
            }
       }     
      dos.close();
      } catch (IOException e) {System.out.println("File IO error");
        }                                                  
    }
//************************************************************************
    public String getAppletInfo() {
        return "Evolution of 2d PDEs ";
    }

//************************************************************************   
    public String[][] getParameterInfo() {
       String[][] info = {
       // Parameter Name  Kind of Value   Description
         {"function",     "int",          "PDE used 0=CGL, 1=Brusselator, 2=Schnackenberg, 3=SH, 4=Barkley, 5=Bar, 6=Lifshitz"},
         {"solvewidth",   "double",       "Width of system (default=64)"},
         {"solveheight",  "double",       "Width of system (default=64)"},
         {"plotwidth",    "double",       "Scaled width for plotting (default=64)"},
         {"plotheight",   "double",       "Scaled height for plotting (default=64)"},
         {"parametersi",  "double",       "i=0,1... parameters of PDE (number and defaults depend on PDE"},
         {"ai",           "double",       "i=0,1.. amplitude of random i.c. for each field (default 0.5)"},
         {"bi",           "double",       "i=0,1.. offset of random i.c. for each field (default 0)"},
         {"dt",           "double",       "Time step (defulat=0.1)"},
         {"mesh",         "double",       "Size of spatial grid (default=1)"},
         {"speed",        "double",       "Number of iterations before plot (default 1)"},
         {"choosePlots",  "boolean",      "User may choose plot type if true"},
         {"plottype",     "int",          "Determines plot (depends on function) default=0)"},
         {"plotspectral", "boolean",      "Plot FFT for spectral code if true (default false)"},
         {"pallette",     "int",          "pallette used in plot 0=PDE default 1=RGB 2=GREY 3=CIRC 4=USER"},
         {"scaleplot",    "boolean",      "Plot scales with window if true (default false)"},
         {"scaleminmax",  "boolean",      "Automatically scale field in plot if true (default)"},
         {"showminmax",   "boolean",      "Show range of field in plot if true (defulat)"},
         {"minimum",      "double",       "Minimum value of field in plot if !scaleminmax (default 0)"},
         {"maximum",      "double",       "Maximum value of field in plot if !scaleminmax (default 1)"},
         {"showtime",     "boolean",      "Time shown in plot if true (default false)"},
         {"filein",       "String",       "File for read in. No read if none (default)"},
         {"fileout",      "String",       "File for write out. No write if none (default)"},
         {"ai",           "double",       "i=0,1.. amplitude of random i.c. for each field (default 0.5)"},
         {"bi",           "double",       "i=0,1.. offset of random i.c. for each field (default 0)"}
       };
       return info;
    }
}
