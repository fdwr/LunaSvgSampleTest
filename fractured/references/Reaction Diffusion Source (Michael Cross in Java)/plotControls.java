import java.applet.Applet;
import java.awt.*;


// Buttons and text input
public class plotControls extends Panel{
    Button button,button1;
    TextField dtBox;
    TextField timeBox;
    Label timeLabel;
    public boolean runAnimation;
    public boolean reset=false;
    private boolean showTime;
    
    Applet applet;
    static LayoutManager dcLayout = new FlowLayout(FlowLayout.LEFT, 5, 5);

    // Constructor
    public plotControls(Applet app, double p1, boolean inShowTime) {
      applet = app;
      showTime=inShowTime;
      setLayout(dcLayout);
      add(new Label("Speed",Label.RIGHT));

      add(dtBox = new TextField(Integer.toString((int)p1), 3));
      add(button = new Button(" Start "));
      button.disable();
//    button.addActionListener(this);           // Java 1.1 event handler
      add(button1=new Button("Reset"));
      button1.disable();
//    button1.addActionListener(this);           // Java 1.1 event handler      
      if(showTime) {
            timeLabel = new Label("Time = 0     ",Label.LEFT);
            add(timeLabel);
      }      
      
      runAnimation=true;
    }
    
    public void addRenderButton() {
//      Moved these lines to constructor
//      add(button = new Button(" Start "));
//      button.disable();
//      add(button1=new Button("Reset"));
//      button1.disable();
//    button.addActionListener(this);           // Java 1.1 event handler
    }
    
      // Java 1.0 event handler
      public boolean action(Event evt, Object arg) {             
         if(evt.target==button) {
           if(runAnimation) {
                  button.disable();
                  runAnimation=false; 
//                Next two lines are for application, not applet
//                applet.stop();
//                applet.destroy();
             }
             else {
                   button.setLabel(" Stop  ");                  
                   runAnimation=true;
                   button1.disable();
                   applet.start();
             }                
             return true;
         }
         else if(evt.target==button1) {
            reset=true;
            if(!runAnimation) {
                button.disable();
                button.setLabel(" Start ");
                runAnimation=true;
                applet.start();
            }    
         return true;
         }       
         else return false;
      }
    
//    Java 1.1 event handler
/*
    public void actionPerformed(ActionEvent e) {
        if (e.getSource() == button) {
            if(runAnimation) {
                 button.setLabel("  Run ");
                 button1.enable();                 
                 runAnimation=false;
//               applet.stop();
//               applet.destroy();
            }
            else {
                  button.setLabel(" Stop  ");                  
                  runAnimation=true;
                  button1.disable();
                  applet.start();
            }      
        }
        else if (e.getSource() == button1) {
           reset=true;
            if(!runAnimation) {
                button.disable();
                button.setLabel(" Start ");
                runAnimation=true;
                applet.start();
            }          
        }
    }
*/    
    // Reads data from GUI and tests for validity
    public void getParams(double[] vals) {
      int iNew;
      double dNew;
      try {
          dNew=(new Double(dtBox.getText())).doubleValue();
      }
      catch (NumberFormatException e) {
          dtBox.setText(Integer.toString((int)vals[0]));
          return;
      }
      vals[0]=dNew;
//      try {
//          dNew=(new Double(parameterBox.getText())).doubleValue();
//      }
//      catch (NumberFormatException e) {
//          parameterBox.setText(String.valueOf(vals[1]));
//          return;
//      }
//      vals[1]=dNew;      
      return;
    }
    
    public void setButtonLabel(String text) {
        button.setLabel(text);
    }
    
    public void setTime(String text) {
        if(showTime) timeLabel.setText(text);
    }    
    
    public void buttonEnable() {
        button.enable();
    }
    
    // Sets buttons ready to start
    public void setStart() {
        button.setLabel(" Start ");
        button1.enable();
        button.enable();
    }                

}

