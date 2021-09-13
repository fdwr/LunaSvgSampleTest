import java.awt.*;
//*********************************************************************
/**
* Array of labelled text fields.<br>
* @version 11 November 1998
* @author Michael Cross
*/
//*********************************************************************
public class plotChoiceControls extends Panel {

/**
* vector of TextFields
*/
       public CheckboxGroup plotFFTCbg ;
       public Checkbox plotFFTYes;
       public Checkbox plotFFTNo ;
       public CheckboxGroup plotTypeCbg;
       public Checkbox[] plotType;
       int nTypes;
       boolean spectral;
           


//*********************************************************************
/** Default constructor
*/
//*********************************************************************
        
      public plotChoiceControls (int n, boolean inSpectral) {
             int nGrid=0;
             nTypes=n;
             spectral=inSpectral;
             if(nTypes>1) nGrid=nGrid+nTypes+1;
             if(spectral) nGrid=nGrid+3;    
             setLayout(new GridLayout(nGrid,1,0,0));
             if(nTypes>1) {
                 add(new Label("Plot type"));
                 plotTypeCbg=new CheckboxGroup();
                 plotType=new Checkbox[nTypes];
                 for(int i=0;i<nTypes;i++) {
                    plotType[i]=new Checkbox(String.valueOf(i+1),plotTypeCbg,true);
                    add(plotType[i]);
                 }   
                 plotType[0].setState(true);  
             }     
             if(spectral) {
                 plotFFTCbg=new CheckboxGroup();
                 plotFFTYes=new Checkbox(" Yes",plotFFTCbg,true);
                 plotFFTNo=new Checkbox(" No",plotFFTCbg,false);
                 add(new Label("Plot FFT"));
                 add(plotFFTYes);
                 add(plotFFTNo);
                 plotFFTNo.setState(true);
             }
                    
      }
      
      
      public int getPlotType() {
            if(nTypes>1)
                for(int i=0;i<nTypes;i++)
                    if(plotType[i].getState()) return i;
            return 0;
      }
      
      public boolean getPlotFFT() {
           if(spectral) return plotFFTYes.getState();
           else return false;
      }
      
      public void setPlotFFT(boolean yesNo) {
        if(spectral) plotFFTYes.setState(yesNo);
        return;
      }  
        
      
      public void setPlotType(int n) {
            if(n<nTypes)
                plotType[n].setState(true);
      }     
                      
            
      public Insets insets() {
         return new Insets(20,20,20,0);
   }


}
//*********************************************************************
//*********************************************************************
