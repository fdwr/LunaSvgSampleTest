import java.awt.*;
//*********************************************************************
/**
* Array of labelled text fields.<br>
* @version 11 November 1998
* @author Michael Cross
*/
//*********************************************************************
public class textControls extends Panel {

/**
* vector of TextFields
*/
        private TextField[] t;
        private Label[] l;
        private Panel[] p;
        private int ntext;           // number of text fields
        private int textLength;
//        private alertDialog alert;

//*********************************************************************
/** Default constructor
* @param text[] vector of text fields of TextBoxes
* @param l[] vector of text fields for labels
* @param n number of TextBoxes
* @param length length of TextBoxes
*/
//*********************************************************************
        
        public textControls (String[] text,
             String[] label, int n, int length) {
             textLength = length;  
             ntext = n;
             setLayout(new GridLayout(n,1,0,0));
             t = new TextField[ntext];
             l = new Label[ntext];
             p = new Panel[ntext];
                          
             for(int i=0;i<n;i++) {
                t[i] = new TextField(text[i],textLength);
                l[i] = new Label(label[i],Label.RIGHT);
                p[i] = new Panel();
                p[i].setLayout(new FlowLayout(FlowLayout.RIGHT));
                add(p[i]);
                p[i].add(l[i]);
                p[i].add(t[i]);
             }           
      }      

//**********************************************************************
/** Constructor with default TextBox length = 8
* @param text[] vector of text fields of TextBoxes
* @param l[] vector of text fields for labels
* @param n number of TextBoxes
*/
//**********************************************************************
      public textControls (String[] text, String[] l, int n) {
          this(text,l,n,8);
      }
      
//*********************************************************************
/**
* Number of controls
* @return number of controls
*/ 
//*********************************************************************
    
      public int ncontrols() {
           return ntext;
      }

//*********************************************************************
/**
* Parses text field known to be integer.  
* Resets old value of corresponding variable if input format
* is incorrect and brings up alertDialog warning box.
* @param n index of textbox to read
* @param i old value of variable
* @return new value of parameter if textbox format is correct,
* otherwise old value.
* @see alertDialog
*/
//*********************************************************************

    public int parseTextField(int n, int i) {
            int iNew;
            if(n>ntext) return i;
            try {
                iNew=(new Integer(t[n].getText())).intValue();
            }
            catch (NumberFormatException e) {
                t[n].setText(String.valueOf(i));
//                alert = new alertDialog(parent,"Try an integer");
                return i;
            }
            return iNew;
   }
//*********************************************************************
/**
* Parses text field known to be integer of known sign.  
* Resets old value of corresponding variable if input format
* is incorrect or wrong sign and brings up alertDialog warning box.
* @param n index of textbox to read
* @param i old value of variable
* @param positive true if value should be positive
* @return new value of parameter if textbox format is correct,
* and value of correct sign, otherwise old value.
* @see alertDialog
*/
//*********************************************************************

    public int parseTextField(int n, int i, boolean positive) {
            int iNew;
            if(n>ntext) return i;
            try {
                iNew=(new Integer(t[n].getText())).intValue();
            }
            catch (NumberFormatException e) {
                t[n].setText(String.valueOf(i));
//                alert = new alertDialog(parent,"Try an integer");
                return i;
            }
            if(((iNew < 0) && positive) || ((iNew>0) && !positive)) {
                t[n].setText(String.valueOf(i));
//                if(positive) alert = new alertDialog(parent,"Must be positive");
//                else alert = new alertDialog(parent,"Must be negative");
                return i;
            }
            return iNew;
   }
//*********************************************************************
/**
* Parses text field known to be integer in known range. 
* Resets old value of corresponding variable if input format
* is incorrect orout of range and brings up alertDialog warning box.
* @param n index of textbox to read
* @param i old value of variable
* @param min minimum value of allowed range
* @param max maximum value of allowed range
* @return new value of parameter if textbox format is correct,
* and value in of range, otherwise old value.
* @see alertDialog
*/
//*********************************************************************

    public int parseTextField(int n, int i, int min, int max) {
            int iNew;
            if(n>ntext) return i;
            try {
                iNew=(new Integer(t[n].getText())).intValue();
            }
            catch (NumberFormatException e) {
                t[n].setText(String.valueOf(i));
//                alert = new alertDialog(parent,"Try an integer");
                return i;
            }
            if((iNew < min) || (iNew > max)) {
                t[n].setText(String.valueOf(i));
//                alert = new alertDialog(parent,"Must be between " + min 
//                        +" and "+max);
                return i;
            }
            return iNew;
   }   
//*********************************************************************
/**
* Parses text field known to be double. 
* Resets old value of corresponding variable if input format
* is incorrect and brings up alertDialog warning box.
* @param n index of textbox to read
* @param d old value of variable
* @return new value of parameter if textbox format is correct,
* otherwise old value.
* @see alertDialog
*/
//*********************************************************************
   
    public double parseTextField(int n, double d) {
            double dNew;
            if(n>ntext) return d;
            try {
                dNew=(new Double(t[n].getText())).doubleValue();
            }
            catch (NumberFormatException e) {
                t[n].setText(String.valueOf(d));
//                alert = new alertDialog
//                                           (parent,"Must be a number");
                return d;
            }
            return dNew;
   }

//*********************************************************************
/**
* Parses text field known to be double and of known sign 
* Resets old value of corresponding variable if input format
* is incorrect or wrong sign and brings up alertDialog warning box.
* @param n index of textbox to read
* @param d old value of variable
* @param positive true if positive, false if negative
* @return new value of parameter if textbox format is correct,
* and value in range, otherwise old value .
* @see alertDialog
*/
//*********************************************************************
   
    public double parseTextField (int n, double d, boolean positive) {
            double dNew;
            if(n>ntext) return d;
            try {
                dNew=(new Double(t[n].getText())).doubleValue();
            }
            catch (NumberFormatException e) {
                t[n].setText(String.valueOf(d));
//                alert = new alertDialog
//                                           (parent,"Must be a number");
                return d;
            }
            if( (dNew <0 && positive) ) {
                t[n].setText(String.valueOf(d));
//                alert = new alertDialog
//                                        (parent,"Must be a positive number");
                return d;
            }
            else if( (dNew > 0 && !positive) ) {
                t[n].setText(String.valueOf(d));
//                alert = new alertDialog
//                                        (parent,"Must be a negative number");
                return d;
            }            
            return dNew;
   }

//*********************************************************************
/**
* Parses text field known to be double and in known range 
* Resets old value of corresponding variable if input format
* is incorrect or out of range and brings up alertDialog warning box.
* @param n index of textbox to read
* @param d old value of variable
* @param min minimum value of allowed range
* @param max maximum value of allowed range
* @return new value of parameter if textbox format is correct,
* and value in range, otherwise old value .
* @see alertDialog
*/
//*********************************************************************
   
    public double parseTextField (int n, double d, double min, double max) {
            double dNew;
            if(n>ntext) return d;
            try {
                dNew=(new Double(t[n].getText())).doubleValue();
            }
            catch (NumberFormatException e) {
                t[n].setText(String.valueOf(d));
//                alert = new alertDialog
//                                           (parent,"Must be a number");
                return d;
            }
            if( (dNew < min) || (dNew > max) ) {
                t[n].setText(String.valueOf(d));
//                alert = new alertDialog
//                     (parent,"Must be between " + min + " and " + max);
                return d;
            }
            return dNew;
   }

//*********************************************************************
/**
* Sets ith label
* @param i index of label
* @param text label
*/ 
//*********************************************************************   
   public void setLabelText(int i, String text) {
      l[i].setText(text);
   }

//*********************************************************************
/**
* Sets value of ith textbox
* @param i index of textbox
* @param text value to be set
*/ 
//*********************************************************************   
   public void setText(int i, String text) {
      t[i].setText(text);
   }
//*********************************************************************
/**
* Gets value of ith textbox
* @param i index of textbox
* @return content of textbox
*/ 
//*********************************************************************    
   public String getText(int i) {
      return t[i].getText();
   }   

//*********************************************************************
/**
* Hides ith label and texbox
* @param i index
*/ 
//*********************************************************************    
   public void hide(int i) {
      l[i].hide();
      t[i].hide();
   }

//*********************************************************************
/**
* Shows ith label and texbox
* @param i index
*/ 
//*********************************************************************    
   public void show(int i) {
      l[i].show();
      t[i].show();
   }   

//*********************************************************************
/**
* Shows all labels and texboxes
*/ 
//*********************************************************************    
   public void showAll() {
      for(int i=0;i<ntext;i++) {
            l[i].show();
            t[i].show();
      }      
   }

//*********************************************************************
/**
* Disables ith text box
* @param i index
*/
//********************************************************************* 
   public void disableText(int i) {
          t[i].disable();
   }

//*********************************************************************
/**
* Enables ith text box
* @param i index
*/
//*********************************************************************    
   public void enableText(int i) {
          t[i].enable();
   }   
      
   public Insets insets() {
       return new Insets(20,0,20,0);
   }
       
}
//*********************************************************************
//*********************************************************************
