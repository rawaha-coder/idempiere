/******************************************************************************
 * Copyright (C) 2008 Low Heng Sin                                            *
 * Copyright (C) 2008 Idalica Corporation                                     *
 * This program is free software; you can redistribute it and/or modify it    *
 * under the terms version 2 of the GNU General Public License as published   *
 * by the Free Software Foundation. This program is distributed in the hope   *
 * that it will be useful, but WITHOUT ANY WARRANTY; without even the implied *
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.           *
 * See the GNU General Public License for more details.                       *
 * You should have received a copy of the GNU General Public License along    *
 * with this program; if not, write to the Free Software Foundation, Inc.,    *
 * 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA.                     *
 *****************************************************************************/
package org.adempiere.webui.desktop;

import java.io.IOException;
import java.util.List;

import org.adempiere.util.Callback;
import org.adempiere.webui.adwindow.ADWindow;
import org.adempiere.webui.apps.ProcessDialog;
import org.adempiere.webui.apps.wf.WFPanel;
import org.adempiere.webui.component.DesktopTabpanel;
import org.adempiere.webui.component.Tabbox;
import org.adempiere.webui.component.Tabpanel;
import org.adempiere.webui.component.Window;
import org.adempiere.webui.panel.ADForm;
import org.adempiere.webui.part.WindowContainer;
import org.adempiere.webui.window.WTask;
import org.compiere.model.MQuery;
import org.compiere.model.MTask;
import org.compiere.util.Env;
import org.compiere.util.WebDoc;
import org.compiere.wf.MWorkflow;
import org.zkoss.image.AImage;
import org.zkoss.util.media.AMedia;
import org.zkoss.zk.ui.Component;
import org.zkoss.zk.ui.event.Event;
import org.zkoss.zk.ui.event.EventListener;
import org.zkoss.zk.ui.event.Events;
import org.zkoss.zul.Iframe;
import org.zkoss.zul.Tab;
import org.zkoss.zul.Tabpanels;

/**
 * A Tabbed MDI implementation
 * @author hengsin
 *
 */
public abstract class TabbedDesktop extends AbstractDesktop {

	private static final String IN_PROGRESS_IMAGE = "~./zk/img/progress3.gif";
	protected WindowContainer windowContainer;

	public TabbedDesktop() {
		super();
		windowContainer = new WindowContainer();
	}

	/**
     *
     * @param processId
     * @param soTrx
     * @return ProcessDialog
     */
	public ProcessDialog openProcessDialog(int processId, boolean soTrx) {
		ProcessDialog pd = new ProcessDialog (processId, soTrx);
		if (pd.isValid()) {
			DesktopTabpanel tabPanel = new DesktopTabpanel();
			pd.setParent(tabPanel);
			String title = pd.getTitle();
			pd.setTitle(null);
			preOpenNewTab();
			windowContainer.addWindow(tabPanel, title, true);
		}
		return pd;
	}

    /**
     *
     * @param formId
     * @return ADWindow
     */
	public ADForm openForm(int formId) {
		ADForm form = ADForm.openForm(formId);

		if (Window.Mode.EMBEDDED == form.getWindowMode()) {
			DesktopTabpanel tabPanel = new DesktopTabpanel();
			form.setParent(tabPanel);
			//do not show window title when open as tab
			form.setTitle(null);
			preOpenNewTab();
			windowContainer.addWindow(tabPanel, form.getFormName(), true);
		} else {
			form.setAttribute(Window.MODE_KEY, form.getWindowMode());
			showWindow(form);
		}

		return form;
	}

	/**
	 *
	 * @param workflow_ID
	 */
	public void openWorkflow(int workflow_ID) {
		WFPanel p = new WFPanel();
		p.load(workflow_ID);

		DesktopTabpanel tabPanel = new DesktopTabpanel();
		p.setParent(tabPanel);
		preOpenNewTab();
		windowContainer.addWindow(tabPanel, p.getWorkflow().get_Translation(MWorkflow.COLUMNNAME_Name), true);
	}

	/**
	 *
	 * @param <T>
	 * @param windowId
	 * @return ADWindow
	 */
	public void openWindow(int windowId, Callback<ADWindow> callback) {
		openWindow(windowId, null, callback);
	}

	/**
	 *
	 * @param windowId
     * @param query
	 * @return ADWindow
	 */
	public void openWindow(int windowId, MQuery query, Callback<ADWindow> callback) {
		final ADWindow adWindow = new ADWindow(Env.getCtx(), windowId, query);

		final DesktopTabpanel tabPanel = new DesktopTabpanel();		
		tabPanel.setId(adWindow.getTitle()+"_"+adWindow.getADWindowContent().getWindowNo());
		final Tab tab = windowContainer.addWindow(tabPanel, adWindow.getTitle(), true);
		tab.setImage(IN_PROGRESS_IMAGE);
		tab.setClosable(false);		
		final OpenWindowRunnable runnable = new OpenWindowRunnable(adWindow, tab, tabPanel, callback);
		tabPanel.addEventListener("onOpenWindow", new EventListener<Event>() {
			@Override
			public void onEvent(Event event) throws Exception {
				runnable.run();
			}
		});				
		Events.echoEvent(new Event("onOpenWindow", tabPanel));
	}

	/**
     *
     * @param taskId
     */
	public void openTask(int taskId) {
		MTask task = new MTask(Env.getCtx(), taskId, null);
		new WTask(task.getName(), task);
	}

	/**
	 * @param url
	 */
	public void showURL(String url, boolean closeable)
    {
    	showURL(url, url, closeable);
    }

	/**
	 *
	 * @param url
	 * @param title
	 * @param closeable
	 */
    public void showURL(String url, String title, boolean closeable)
    {
    	Iframe iframe = new Iframe(url);
    	addWin(iframe, title, closeable);
    }

    /**
     * @param webDoc
     * @param title
     * @param closeable
     */
    public void showURL(WebDoc webDoc, String title, boolean closeable)
    {
    	Iframe iframe = new Iframe();

    	AMedia media = new AMedia(title, "html", "text/html", webDoc.toString().getBytes());
    	iframe.setContent(media);

    	addWin(iframe, title, closeable);
    }

    /**
     *
     * @param fr
     * @param title
     * @param closeable
     */
    private void addWin(Iframe fr, String title, boolean closeable)
    {
    	fr.setWidth("100%");
        fr.setHeight("100%");
        fr.setStyle("padding: 0; margin: 0; border: none; position: absolute");
        Window window = new Window();
        window.setWidth("100%");
        window.setHeight("100%");
        window.setStyle("padding: 0; margin: 0; border: none");
        window.appendChild(fr);
        window.setStyle("position: absolute");

        Tabpanel tabPanel = new Tabpanel();
    	window.setParent(tabPanel);
    	preOpenNewTab();
    	windowContainer.addWindow(tabPanel, title, closeable);
    }

    /**
     * @param AD_Window_ID
     * @param query
     */
    public void showZoomWindow(int AD_Window_ID, MQuery query)
    {
    	final ADWindow wnd = new ADWindow(Env.getCtx(), AD_Window_ID, query);

    	final DesktopTabpanel tabPanel = new DesktopTabpanel();		
		final Tab tab = windowContainer.insertAfter(windowContainer.getSelectedTab(), tabPanel, wnd.getTitle(), true, true);
		tab.setImage(IN_PROGRESS_IMAGE);
		tab.setClosable(false);		
		final OpenWindowRunnable runnable = new OpenWindowRunnable(wnd, tab, tabPanel, null);
		tabPanel.addEventListener("onOpenWindow", new EventListener<Event>() {
			@Override
			public void onEvent(Event event) throws Exception {
				runnable.run();
			}
		});				
		Events.echoEvent(new Event("onOpenWindow", tabPanel));
	}

    /**
     * @param AD_Window_ID
     * @param query
     * @deprecated
     */
    public void showWindow(int AD_Window_ID, MQuery query)
    {
    	openWindow(AD_Window_ID, query, null);
	}

	/**
	 *
	 * @param window
	 */
	protected void showEmbedded(Window window)
   	{
		Tabpanel tabPanel = new Tabpanel();
    	window.setParent(tabPanel);
    	String title = window.getTitle();
    	window.setTitle(null);
    	preOpenNewTab();
    	if (Window.INSERT_NEXT.equals(window.getAttribute(Window.INSERT_POSITION_KEY)))
    		windowContainer.insertAfter(windowContainer.getSelectedTab(), tabPanel, title, true, true);
    	else
    		windowContainer.addWindow(tabPanel, title, true);
   	}

	/**
	 * Close active tab
	 * @return boolean
	 */
	public boolean closeActiveWindow()
	{
		if (windowContainer.getSelectedTab() != null)
		{
			Tabpanel panel = (Tabpanel) windowContainer.getSelectedTab().getLinkedPanel();
			Component component = panel.getFirstChild();
			Object att = component.getAttribute(WINDOWNO_ATTRIBUTE);

			if ( windowContainer.closeActiveWindow() )
			{
				if (att != null && (att instanceof Integer))
				{
					unregisterWindow((Integer) att);
				}
				return true;
			}
			else
			{
				return false;
			}
		}
		return false;
	}

	/**
	 * @return Component
	 */
	public Component getActiveWindow()
	{
		return windowContainer.getSelectedTab().getLinkedPanel().getFirstChild();
	}

	/**
	 *
	 * @param windowNo
	 * @return boolean
	 */
	public boolean closeWindow(int windowNo)
	{
		Tabbox tabbox = windowContainer.getComponent();
		Tabpanels panels = tabbox.getTabpanels();
		List<?> childrens = panels.getChildren();
		for (Object child : childrens)
		{
			Tabpanel panel = (Tabpanel) child;
			Component component = panel.getFirstChild();
			Object att = component.getAttribute(WINDOWNO_ATTRIBUTE);
			if (att != null && (att instanceof Integer))
			{
				if (windowNo == (Integer)att)
				{
					Tab tab = panel.getLinkedTab();
					panel.getLinkedTab().onClose();
					if (tab.getParent() == null)
					{
						unregisterWindow(windowNo);
						return true;
					}
					else
					{
						return false;
					}
				}
			}
		}
		return false;
	}
	
	/**
	 * invoke before a new tab is added to the desktop
	 */
	protected void preOpenNewTab()
	{
	}
	
	class OpenWindowRunnable implements Runnable {

		private final ADWindow adWindow;
		private final Tab tab;
		private final DesktopTabpanel tabPanel;
		private Callback<ADWindow> callback;

		protected OpenWindowRunnable(ADWindow adWindow, Tab tab, DesktopTabpanel tabPanel, Callback<ADWindow> callback) {
			this.adWindow = adWindow;
			this.tab = tab;
			this.tabPanel = tabPanel;
			this.callback = callback;
		}
		
		@Override
		public void run() {
			preOpenNewTab();
			if (adWindow.createPart(tabPanel) != null ) {
				tab.setImage(null);
				tab.setClosable(true);
				if (adWindow.getMImage() != null) {
					try {
						AImage aImage = adWindow.getAImage();
						tab.setImageContent(aImage);
					} catch (IOException e) {
					}
				}
				if (callback != null) {
					callback.onCallback(adWindow);
				}
			} else {
				tab.onClose();
			}
		}		
	}
}
