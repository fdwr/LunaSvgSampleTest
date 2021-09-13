// Mirek's Java Cellebration
// http://www.mirekw.com
//
// Patterns list
// Patterns names are read from the resource file 'pat.txt'.

import java.awt.*;
import java.awt.event.*;
import java.util.*;

public class MJPatternsList extends Dialog implements ActionListener {
	private Button btnLoad, btnCcl;
	private Label lblPrompt;
	private java.awt.List LstFiles = new java.awt.List(10, false);
	private MJCellUI mjUI;
	private String sRuleName;
	private String sGameName;
	private Vector vPatterns[] = new Vector[MJRules.GAME_LAST + 1];

	// ----------------------------------------------------------------
	// Constructor
	MJPatternsList(Frame frame, MJCellUI mjui) {
		super(frame, "CA patterns", false);
		mjUI = mjui;
		setLayout(new BorderLayout());
		lblPrompt = new Label("Select the pattern:");
		add("North", lblPrompt);
		add("Center", LstFiles);

		Panel pnlButtons = new Panel();
		pnlButtons.setLayout(new FlowLayout());
		pnlButtons.add(btnLoad = new Button(" Load "));
		btnLoad.addActionListener(this);
		pnlButtons.add(btnCcl = new Button("Cancel"));
		btnCcl.addActionListener(this);
		add("South", pnlButtons);

		Dimension d = getToolkit().getScreenSize();
		setLocation(d.width / 4, d.height / 3);
		setSize(d.width / 6, d.height / 3);
		setVisible(false);
		for (int i = 0; i <= MJRules.GAME_LAST; i++) {
			vPatterns[i] = new Vector();
		}
		AddPatterns();
		InitList();
	}

	// ----------------------------------------------------------------
	// Fill the vector with all available patterns
	private void AddPatterns() {
		MJTools mjT;
		Vector vLines;
		int i = -1, iGame = -1;
		String sBff;

		vLines = new Vector();
		mjT = new MJTools();
		if (mjT.LoadResTextFile("pat.txt", vLines)) // load the file with pattern names
		{
			for (i = 0; i < vLines.size(); i++) {
				sBff = ((String) vLines.elementAt(i)).trim();
				if ((sBff.length() > 0)
						&& !((String) vLines.elementAt(i)).startsWith("//")) {
					if (sBff.startsWith("#")) // next family of rules
					{
						iGame = mjUI.mjr.GetGameIndex(sBff.substring(1));
					} else // next pattern
					{
						if (mjUI.mjr.IsGameIdxValid(iGame))
							vPatterns[iGame].addElement(sBff);
					}
				}
			}
		}
	}

	// ----------------------------------------------------------------
	// Fill the list with patterns only from the current rule
	public void InitList() {
		int i, iGame;
		sRuleName = mjUI.cmbRules.getSelectedItem();
		sGameName = mjUI.cmbGames.getSelectedItem();

		LstFiles.clear();
		iGame = mjUI.mjr.GetGameIndex(sGameName);
		if (mjUI.mjr.IsGameIdxValid(iGame))
			for (i = 0; i < vPatterns[iGame].size(); i++)
				if (((String) vPatterns[iGame].elementAt(i))
						.startsWith(sRuleName + "/"))
					LstFiles.add(((String) vPatterns[iGame].elementAt(i))
							.substring(sRuleName.length() + 1));
	}

	// ----------------------------------------------------------------
	// Load the currently selected pattern
	private void LoadCurrentPattern() {
		if (LstFiles.getSelectedIndex() >= 0) {
			String sItem = LstFiles.getSelectedItem();
			lblPrompt.setText("Please wait...");
			try {
				mjUI.mjo.OpenFile(sGameName + "/" + sRuleName + "/" + sItem);
				lblPrompt.setText("Select the pattern:");
			} catch (Exception exc) {
				lblPrompt.setText("Error loading pattern!");
			}
		}
	}

	// ----------------------------------------------------------------
	public void actionPerformed(ActionEvent ae) {
		if (ae.getSource() == btnLoad) {
			LoadCurrentPattern();
		} else if (ae.getSource() == btnCcl) {
			setVisible(false);
		}
	}

	// ----------------------------------------------------------------
	public boolean action(Event evt, Object arg) {
		if (evt.target.equals(LstFiles)) {
			LoadCurrentPattern();
		} else
			return super.action(evt, arg);
		return true;
	}

	// ----------------------------------------------------------------
	public boolean handleEvent(Event evt) {
		if (evt.id == Event.WINDOW_DESTROY)
			setVisible(false);
		else
			return super.handleEvent(evt);
		return true;
	}
	// ----------------------------------------------------------------

}