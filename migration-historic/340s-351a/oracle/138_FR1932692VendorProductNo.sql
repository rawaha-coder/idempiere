DROP VIEW C_ORDER_LINETAX_V;
CREATE OR REPLACE VIEW C_ORDER_LINETAX_V
(AD_CLIENT_ID, AD_ORG_ID, ISACTIVE, CREATED, CREATEDBY, 
 UPDATED, UPDATEDBY, AD_LANGUAGE, C_ORDER_ID, C_ORDERLINE_ID, 
 C_TAX_ID, TAXINDICATOR, C_BPARTNER_ID, C_BPARTNER_LOCATION_ID, BPNAME, 
 C_LOCATION_ID, LINE, M_PRODUCT_ID,VendorProductNo, QTYORDERED, QTYENTERED, 
 UOMSYMBOL, NAME, DESCRIPTION, DOCUMENTNOTE, UPC, 
 SKU, PRODUCTVALUE, RESOURCEDESCRIPTION, PRICELIST, PRICEENTEREDLIST, 
 DISCOUNT, PRICEACTUAL, PRICEENTERED, LINENETAMT, PRODUCTDESCRIPTION, 
 IMAGEURL, C_CAMPAIGN_ID, C_PROJECT_ID, C_ACTIVITY_ID, C_PROJECTPHASE_ID, 
 C_PROJECTTASK_ID)
AS 
SELECT ol.AD_Client_ID, ol.AD_Org_ID, ol.IsActive, ol.Created, ol.CreatedBy, ol.Updated, ol.UpdatedBy,
	'en_US' AS AD_Language,
	ol.C_Order_ID, ol.C_OrderLine_ID, ol.C_Tax_ID, t.TaxIndicator,
    ol.C_BPartner_ID, ol.C_BPartner_Location_ID, bp.Name AS BPName, bpl.C_Location_ID,
	ol.Line, p.M_Product_ID, po.VendorProductNo,
	CASE WHEN ol.QtyOrdered<>0 OR ol.M_Product_ID IS NOT NULL THEN ol.QtyOrdered END AS QtyOrdered,
    CASE WHEN ol.QtyEntered<>0 OR ol.M_Product_ID IS NOT NULL THEN ol.QtyEntered END AS QtyEntered,
    CASE WHEN ol.QtyEntered<>0 OR ol.M_Product_ID IS NOT NULL THEN uom.UOMSymbol END AS UOMSymbol,
	COALESCE(c.Name,p.Name||productAttribute(ol.M_AttributeSetInstance_ID), ol.Description) AS Name, -- main line
	CASE WHEN COALESCE(c.Name,p.Name) IS NOT NULL THEN ol.Description END AS Description, -- second line
	p.DocumentNote, -- third line
    p.UPC, p.SKU, COALESCE(pp.VendorProductNo,p.Value) AS ProductValue,
	ra.Description AS ResourceDescription, -- forth line
	CASE WHEN i.IsDiscountPrinted='Y' AND ol.PriceList<>0
        THEN ol.PriceList END AS PriceList,
	CASE WHEN i.IsDiscountPrinted='Y' AND ol.PriceList<>0 AND ol.QtyEntered<>0
        THEN ol.PriceList*ol.QtyOrdered/ol.QtyEntered END AS PriceEnteredList,
	CASE WHEN i.IsDiscountPrinted='Y' AND ol.PriceList>ol.PriceActual AND ol.PriceList<>0
        THEN (ol.PriceList-ol.PriceActual)/ol.PriceList*100 END AS Discount,
	CASE WHEN ol.PriceActual<>0 OR ol.M_Product_ID IS NOT NULL THEN ol.PriceActual END AS PriceActual,
	CASE WHEN ol.PriceEntered<>0 OR ol.M_Product_ID IS NOT NULL THEN ol.PriceEntered END AS PriceEntered,
	CASE WHEN ol.LineNetAmt<>0 OR ol.M_Product_ID IS NOT NULL THEN ol.LineNetAmt END AS LineNetAmt,
    p.Description as ProductDescription, p.ImageURL,
    ol.C_Campaign_ID, ol.C_Project_ID, ol.C_Activity_ID, ol.C_ProjectPhase_ID, ol.C_ProjectTask_ID
FROM C_OrderLine ol
	INNER JOIN C_UOM uom ON (ol.C_UOM_ID=uom.C_UOM_ID)
	INNER JOIN C_Order i ON (ol.C_Order_ID=i.C_Order_ID)
	LEFT OUTER JOIN M_Product p ON (ol.M_Product_ID=p.M_Product_ID)
	LEFT OUTER JOIN M_Product_PO po ON (p.M_Product_ID=po.M_Product_ID)
	LEFT OUTER JOIN S_ResourceAssignment ra ON (ol.S_ResourceAssignment_ID=ra.S_ResourceAssignment_ID)
	LEFT OUTER JOIN C_Charge c ON (ol.C_Charge_ID=c.C_Charge_ID)
    LEFT OUTER JOIN C_BPartner_Product pp ON (ol.M_Product_ID=pp.M_Product_ID AND i.C_BPartner_ID=pp.C_BPartner_ID)
	INNER JOIN C_BPartner bp ON (ol.C_BPartner_ID=bp.C_BPartner_ID)
	INNER JOIN C_BPartner_Location bpl ON (ol.C_BPartner_Location_ID=bpl.C_BPartner_Location_ID)
	LEFT OUTER JOIN C_Tax t ON (ol.C_Tax_ID=t.C_Tax_ID)
UNION
SELECT ol.AD_Client_ID, ol.AD_Org_ID, ol.IsActive, ol.Created, ol.CreatedBy, ol.Updated, ol.UpdatedBy,
	'en_US' AS AD_Language,
	ol.C_Order_ID, ol.C_OrderLine_ID, ol.C_Tax_ID, null,
    null, null, null, null,
	ol.Line+(bl.Line/100) AS Line, p.M_Product_ID,po.VendorProductNo,
    --ol.QtyOrdered*bl.BOMQty AS QtyInvoiced
	CASE WHEN bl.IsQtyPercentage = 'N' THEN ol.QtyOrdered*bl.QtyBOM ELSE ol.QtyOrdered*(bl.QtyBatch / 100) END AS QtyInvoiced, 	
	--ol.QtyEntered*bl.BOMQty AS QtyEntered, 
	CASE WHEN bl.IsQtyPercentage = 'N' THEN ol.QtyEntered*bl.QtyBOM ELSE ol.QtyEntered*(bl.QtyBatch / 100) END AS QtyEntered, 	
	uom.UOMSymbol,
	p.Name,	-- main
	bl.Description,
	p.DocumentNote, p.UPC, p.SKU, p.Value AS ProductValue,
	null, null, null, null, null, null, null, p.Description as ProductDescription, p.ImageURL,
    ol.C_Campaign_ID, ol.C_Project_ID, ol.C_Activity_ID, ol.C_ProjectPhase_ID, ol.C_ProjectTask_ID
/*FROM M_Product_BOM b	-- BOM lines
	INNER JOIN C_OrderLine ol ON (b.M_Product_ID=ol.M_Product_ID)
	INNER JOIN M_Product bp ON (bp.M_Product_ID=ol.M_Product_ID -- BOM Product
		AND bp.IsBOM='Y' AND bp.IsVerified='Y' AND bp.IsInvoicePrintDetails='Y')
	INNER JOIN M_Product p ON (b.M_ProductBOM_ID=p.M_Product_ID) -- BOM line product
	INNER JOIN C_UOM uom ON (p.C_UOM_ID=uom.C_UOM_ID)*/
FROM PP_Product_BOM b 	
	INNER JOIN  C_OrderLine ol ON (b.M_Product_ID=ol.M_Product_ID)
	INNER JOIN  M_Product bp ON (bp.M_Product_ID=ol.M_Product_ID -- BOM Product
		AND bp.IsBOM='Y' AND bp.IsVerified='Y' AND bp.IsInvoicePrintDetails='Y')
	INNER JOIN PP_Product_BOMLine bl ON (bl.PP_Product_BOM_ID=b.PP_Product_BOM_ID)
	INNER JOIN M_Product p ON (p.M_Product_ID=bl.M_Product_ID) -- BOM line product
	LEFT OUTER JOIN M_Product_PO po ON (p.M_Product_ID=po.M_Product_ID)
	INNER JOIN C_UOM uom ON (p.C_UOM_ID=uom.C_UOM_ID)
UNION
SELECT AD_Client_ID, AD_Org_ID, IsActive, Created, CreatedBy, Updated, UpdatedBy,
	'en_US', C_Order_ID, null, null, null,
	null,
	null, null, null,
    null, null, null, null,
	null, null,null,
	null, null, null, null, null, null,
	null, null, null, null, null, null, null, null,
    null,null,null,null,null
FROM C_Order
UNION
SELECT ot.AD_Client_ID, ot.AD_Org_ID, ot.IsActive, ot.Created, ot.CreatedBy, ot.Updated, ot.UpdatedBy,
	'en_US', ot.C_Order_ID, null, ot.C_Tax_ID, t.TaxIndicator,
    null, null, null, null,
	null, null,null,
	null, null, null,
	t.Name,
	null, null, null, null, null, null,
	null, null, null,
    CASE WHEN ot.IsTaxIncluded='Y' THEN ot.TaxAmt ELSE ot.TaxBaseAmt END,
    CASE WHEN ot.IsTaxIncluded='Y' THEN ot.TaxAmt ELSE ot.TaxBaseAmt END,
    CASE WHEN ot.IsTaxIncluded='Y' THEN NULL ELSE ot.TaxAmt END,
    null, null,
    null,null,null,null,null
FROM C_OrderTax ot
	INNER JOIN C_Tax t ON (ot.C_Tax_ID=t.C_Tax_ID);


DROP VIEW C_ORDER_LINETAX_VT;
CREATE OR REPLACE VIEW C_ORDER_LINETAX_VT
(AD_CLIENT_ID, AD_ORG_ID, ISACTIVE, CREATED, CREATEDBY, 
 UPDATED, UPDATEDBY, AD_LANGUAGE, C_ORDER_ID, C_ORDERLINE_ID, 
 C_TAX_ID, TAXINDICATOR, C_BPARTNER_ID, C_BPARTNER_LOCATION_ID, BPNAME, 
 C_LOCATION_ID, LINE, M_PRODUCT_ID,VendorProductNo, QTYORDERED, QTYENTERED, 
 UOMSYMBOL, NAME, DESCRIPTION, DOCUMENTNOTE, UPC, 
 SKU, PRODUCTVALUE, RESOURCEDESCRIPTION, PRICELIST, PRICEENTEREDLIST, 
 DISCOUNT, PRICEACTUAL, PRICEENTERED, LINENETAMT, PRODUCTDESCRIPTION, 
 IMAGEURL, C_CAMPAIGN_ID, C_PROJECT_ID, C_ACTIVITY_ID, C_PROJECTPHASE_ID, 
 C_PROJECTTASK_ID)
AS 
SELECT ol.AD_Client_ID, ol.AD_Org_ID, ol.IsActive, ol.Created, ol.CreatedBy, ol.Updated, ol.UpdatedBy,
	uom.AD_Language,
	ol.C_Order_ID, ol.C_OrderLine_ID, ol.C_Tax_ID, t.TaxIndicator,
    ol.C_BPartner_ID, ol.C_BPartner_Location_ID, bp.Name AS BPName, bpl.C_Location_ID,
	ol.Line, p.M_Product_ID,po.VendorProductNo,
	CASE WHEN ol.QtyOrdered<>0 OR ol.M_Product_ID IS NOT NULL THEN ol.QtyOrdered END AS QtyOrdered,
    CASE WHEN ol.QtyEntered<>0 OR ol.M_Product_ID IS NOT NULL THEN ol.QtyEntered END AS QtyEntered,
    CASE WHEN ol.QtyEntered<>0 OR ol.M_Product_ID IS NOT NULL THEN uom.UOMSymbol END AS UOMSymbol,
	COALESCE(pt.Name,c.Name,p.Name||productAttribute(ol.M_AttributeSetInstance_ID), ol.Description) AS Name, -- main line
	CASE WHEN COALESCE(c.Name,pt.Name, p.Name) IS NOT NULL THEN ol.Description END AS Description, -- second line
	COALESCE(pt.DocumentNote, p.DocumentNote) AS DocumentNote, -- third line
    p.UPC, p.SKU, COALESCE(pp.VendorProductNo,p.Value) AS ProductValue,
	ra.Description AS ResourceDescription, -- forth line
	CASE WHEN i.IsDiscountPrinted='Y' AND ol.PriceList<>0
        THEN ol.PriceList END AS PriceList,
	CASE WHEN i.IsDiscountPrinted='Y' AND ol.PriceList<>0 AND ol.QtyEntered<>0
        THEN ol.PriceList*ol.QtyOrdered/ol.QtyEntered END AS PriceEnteredList,
	CASE WHEN i.IsDiscountPrinted='Y' AND ol.PriceList>ol.PriceActual AND ol.PriceList<>0
        THEN (ol.PriceList-ol.PriceActual)/ol.PriceList*100 END AS Discount,
	CASE WHEN ol.PriceActual<>0 OR ol.M_Product_ID IS NOT NULL THEN ol.PriceActual END AS PriceActual,
	CASE WHEN ol.PriceEntered<>0 OR ol.M_Product_ID IS NOT NULL THEN ol.PriceEntered END AS PriceEntered,
	CASE WHEN ol.LineNetAmt<>0 OR ol.M_Product_ID IS NOT NULL THEN ol.LineNetAmt END AS LineNetAmt,
    pt.Description as ProductDescription, p.ImageURL,
    ol.C_Campaign_ID, ol.C_Project_ID, ol.C_Activity_ID, ol.C_ProjectPhase_ID, ol.C_ProjectTask_ID
FROM C_OrderLine ol
	INNER JOIN C_UOM_Trl uom ON (ol.C_UOM_ID=uom.C_UOM_ID)
	INNER JOIN C_Order i ON (ol.C_Order_ID=i.C_Order_ID)
	LEFT OUTER JOIN M_Product p ON (ol.M_Product_ID=p.M_Product_ID)
	LEFT OUTER JOIN M_Product_PO po ON (p.M_Product_ID=po.M_Product_ID)
	LEFT OUTER JOIN M_Product_Trl pt ON (ol.M_Product_ID=pt.M_Product_ID AND uom.AD_Language=pt.AD_Language)
	LEFT OUTER JOIN S_ResourceAssignment ra ON (ol.S_ResourceAssignment_ID=ra.S_ResourceAssignment_ID)
	LEFT OUTER JOIN C_Charge c ON (ol.C_Charge_ID=c.C_Charge_ID)
    LEFT OUTER JOIN C_BPartner_Product pp ON (ol.M_Product_ID=pp.M_Product_ID AND i.C_BPartner_ID=pp.C_BPartner_ID)
	INNER JOIN C_BPartner bp ON (ol.C_BPartner_ID=bp.C_BPartner_ID)
	INNER JOIN C_BPartner_Location bpl ON (ol.C_BPartner_Location_ID=bpl.C_BPartner_Location_ID)
	LEFT OUTER JOIN C_Tax_Trl t ON (ol.C_Tax_ID=t.C_Tax_ID AND uom.AD_Language=t.AD_Language)
UNION
SELECT ol.AD_Client_ID, ol.AD_Org_ID, ol.IsActive, ol.Created, ol.CreatedBy, ol.Updated, ol.UpdatedBy,
	uom.AD_Language,
	ol.C_Order_ID, ol.C_OrderLine_ID, ol.C_Tax_ID, null,
    null, null, null, null,
	ol.Line+(bl.Line/100) AS Line, p.M_Product_ID,po.VendorProductNo,
	--ol.QtyOrdered*b.BOMQty AS QtyInvoiced, 
	CASE WHEN bl.IsQtyPercentage = 'N' THEN ol.QtyOrdered*bl.QtyBOM ELSE ol.QtyOrdered*(bl.QtyBatch / 100) END AS QtyInvoiced,
	--ol.QtyEntered*b.BOMQty AS QtyEntered, 
	CASE WHEN bl.IsQtyPercentage = 'N' THEN ol.QtyEntered*bl.QtyBOM ELSE ol.QtyEntered*(bl.QtyBatch / 100) END AS QtyEntered,
	uom.UOMSymbol,
	COALESCE(pt.Name, p.Name) AS Name,	-- main
	b.Description,
	COALESCE(pt.DocumentNote, p.DocumentNote) AS DocumentNote, p.UPC, p.SKU, p.Value AS ProductValue,
	null, null, null, null, null, null, null, pt.Description AS ProductDescription, p.ImageURL,
    ol.C_Campaign_ID, ol.C_Project_ID, ol.C_Activity_ID, ol.C_ProjectPhase_ID, ol.C_ProjectTask_ID
/*FROM M_Product_BOM b	-- BOM lines
	INNER JOIN C_OrderLine ol ON (b.M_Product_ID=ol.M_Product_ID)
	INNER JOIN M_Product bp ON (bp.M_Product_ID=ol.M_Product_ID -- BOM Product
		AND bp.IsBOM='Y' AND bp.IsVerified='Y' AND bp.IsInvoicePrintDetails='Y')
	INNER JOIN M_Product p ON (b.M_ProductBOM_ID=p.M_Product_ID) -- BOM line product
	INNER JOIN C_UOM_Trl uom ON (p.C_UOM_ID=uom.C_UOM_ID)
	INNER JOIN M_Product_Trl pt ON (b.M_ProductBOM_ID=pt.M_Product_ID AND uom.AD_Language=pt.AD_Language)*/
FROM PP_Product_BOM b 	
	INNER JOIN C_ORDERLINE ol ON (b.M_Product_ID=ol.M_Product_ID)
	INNER JOIN M_PRODUCT bp ON (bp.M_Product_ID=ol.M_Product_ID -- BOM Product
		AND bp.IsBOM='Y' AND bp.IsVerified='Y' AND bp.IsInvoicePrintDetails='Y')
	INNER JOIN PP_Product_BOMLine bl ON (bl.PP_Product_BOM_ID=b.PP_Product_BOM_ID)
	INNER JOIN M_Product p ON (p.M_Product_ID=bl.M_Product_ID) -- BOM line product
	LEFT OUTER JOIN M_Product_PO po ON (p.M_Product_ID=po.M_Product_ID)
	INNER JOIN C_UOM_Trl uom ON (p.C_UOM_ID=uom.C_UOM_ID)
	INNER JOIN M_Product_Trl pt ON (pt.M_Product_ID=bl.M_Product_ID AND uom.AD_Language=pt.AD_Language)
UNION
SELECT o.AD_Client_ID, o.AD_Org_ID, o.IsActive, o.Created, o.CreatedBy, o.Updated, o.UpdatedBy,
	l.AD_Language, o.C_Order_ID, null, null, null,
	null,
	null, null, null,
    null, null, null, null,
	null, null,null,
	null, null, null, null, null, null,
	null, null, null, null, null, null, null, null,
    null,null,null,null,null
FROM C_Order o, AD_Language l
WHERE l.IsBaseLanguage='N' AND l.IsSystemLanguage='Y'
UNION
SELECT ot.AD_Client_ID, ot.AD_Org_ID, ot.IsActive, ot.Created, ot.CreatedBy, ot.Updated, ot.UpdatedBy,
	t.AD_Language, ot.C_Order_ID, null, ot.C_Tax_ID, t.TaxIndicator,
    null, null, null, null,
	null, null,null,
	null, null, null,
	t.Name,
	null, null, null, null, null, null,
	null, null, null,
    CASE WHEN ot.IsTaxIncluded='Y' THEN ot.TaxAmt ELSE ot.TaxBaseAmt END,
    CASE WHEN ot.IsTaxIncluded='Y' THEN ot.TaxAmt ELSE ot.TaxBaseAmt END,
    CASE WHEN ot.IsTaxIncluded='Y' THEN NULL ELSE ot.TaxAmt END,
    null, null,
    null,null,null,null,null
FROM C_OrderTax ot
	INNER JOIN C_Tax_Trl t ON (ot.C_Tax_ID=t.C_Tax_ID);



-- 02-abr-2008 16:08:50 CST
-- FR  1932692 http://sourceforge.net/tracker/index.php?func=detail&aid=1932692&group_id=176962&atid=879335
INSERT INTO AD_Column (AD_Client_ID,AD_Column_ID,AD_Element_ID,AD_Org_ID,AD_Reference_ID,AD_Table_ID,ColumnName,Created,CreatedBy,Description,EntityType,FieldLength,Help,IsActive,IsAlwaysUpdateable,IsEncrypted,IsIdentifier,IsKey,IsMandatory,IsParent,IsSelectionColumn,IsSyncDatabase,IsTranslated,IsUpdateable,Name,SeqNo,Updated,UpdatedBy,Version) VALUES (0,55199,623,0,10,497,'VendorProductNo',TO_DATE('2008-04-02 16:08:49','YYYY-MM-DD HH24:MI:SS'),0,'Product Key of the Business Partner','D',30,'The Business Partner Product Key identifies the number used by the Business Partner for this product. It can be printed on orders and invoices when you include the Product Key in the print format.','Y','N','N','N','N','N','N','N','N','N','Y','Partner Product Key',0,TO_DATE('2008-04-02 16:08:49','YYYY-MM-DD HH24:MI:SS'),0,0)
;

-- 02-abr-2008 16:08:50 CST
-- FR  1932692 http://sourceforge.net/tracker/index.php?func=detail&aid=1932692&group_id=176962&atid=879335
INSERT INTO AD_Column_Trl (AD_Language,AD_Column_ID, Name, IsTranslated,AD_Client_ID,AD_Org_ID,Created,Createdby,Updated,UpdatedBy) SELECT l.AD_Language,t.AD_Column_ID, t.Name, 'N',t.AD_Client_ID,t.AD_Org_ID,t.Created,t.Createdby,t.Updated,t.UpdatedBy FROM AD_Language l, AD_Column t WHERE l.IsActive='Y' AND l.IsSystemLanguage='Y' AND l.IsBaseLanguage='N' AND t.AD_Column_ID=55199 AND EXISTS (SELECT * FROM AD_Column_Trl tt WHERE tt.AD_Language!=l.AD_Language OR tt.AD_Column_ID!=t.AD_Column_ID)
;

-- 02-abr-2008 16:10:34 CST
-- FR  1932692 http://sourceforge.net/tracker/index.php?func=detail&aid=1932692&group_id=176962&atid=879335
INSERT INTO AD_PrintFormatItem (AD_Client_ID,AD_Column_ID,AD_Org_ID,AD_PrintColor_ID,AD_PrintFont_ID,AD_PrintFormatItem_ID,AD_PrintFormat_ID,ArcDiameter,BelowColumn,Created,CreatedBy,FieldAlignmentType,ImageIsAttached,IsActive,IsAveraged,IsCentrallyMaintained,IsCounted,IsDeviationCalc,IsFilledRectangle,IsFixedWidth,IsGroupBy,IsHeightOneLine,IsImageField,IsMaxCalc,IsMinCalc,IsNextLine,IsNextPage,IsOrderBy,IsPageBreak,IsPrinted,IsRelativePosition,IsRunningTotal,IsSetNLPosition,IsSummarized,IsSuppressNull,IsVarianceCalc,LineAlignmentType,LineWidth,MaxHeight,MaxWidth,Name,PrintAreaType,PrintFormatType,PrintName,RunningTotalLines,SeqNo,ShapeType,SortNo,Updated,UpdatedBy,XPosition,XSpace,YPosition,YSpace) VALUES (0,55199,0,100,130,50477,101,0,0,TO_DATE('2008-04-02 16:10:34','YYYY-MM-DD HH24:MI:SS'),0,'D','N','Y','N','N','N','N','N','N','N','Y','N','N','N','Y','N','N','N','Y','Y','N','N','N','N','N','X',1,0,0,'VendorProductNo','C','F','VendorProductNo',20,110,'N',0,TO_DATE('2008-04-02 16:10:34','YYYY-MM-DD HH24:MI:SS'),0,0,0,0,0)
;

-- 02-abr-2008 16:10:34 CST
-- FR  1932692 http://sourceforge.net/tracker/index.php?func=detail&aid=1932692&group_id=176962&atid=879335
INSERT INTO AD_PrintFormatItem_Trl (AD_Language,AD_PrintFormatItem_ID, PrintName,PrintNameSuffix, IsTranslated,AD_Client_ID,AD_Org_ID,Created,Createdby,Updated,UpdatedBy) SELECT l.AD_Language,t.AD_PrintFormatItem_ID, t.PrintName,t.PrintNameSuffix, 'N',t.AD_Client_ID,t.AD_Org_ID,t.Created,t.Createdby,t.Updated,t.UpdatedBy FROM AD_Language l, AD_PrintFormatItem t WHERE l.IsActive='Y' AND l.IsSystemLanguage='Y' AND l.IsBaseLanguage='N' AND t.AD_PrintFormatItem_ID=50477 AND EXISTS (SELECT * FROM AD_PrintFormatItem_Trl tt WHERE tt.AD_Language!=l.AD_Language OR tt.AD_PrintFormatItem_ID!=t.AD_PrintFormatItem_ID)
;

-- 02-abr-2008 16:10:35 CST
-- FR  1932692 http://sourceforge.net/tracker/index.php?func=detail&aid=1932692&group_id=176962&atid=879335
UPDATE AD_PrintFormatItem_Trl trl SET PrintName = (SELECT e.PrintName FROM AD_Element_Trl e, AD_Column c WHERE e.AD_Language=trl.AD_Language AND e.AD_Element_ID=c.AD_Element_ID AND c.AD_Column_ID=55199) WHERE AD_PrintFormatItem_ID = 50477 AND EXISTS (SELECT * FROM AD_Element_Trl e, AD_Column c WHERE e.AD_Language=trl.AD_Language AND e.AD_Element_ID=c.AD_Element_ID AND c.AD_Column_ID=55199 AND trl.AD_PrintFormatItem_ID = 50477) AND EXISTS (SELECT * FROM AD_Client WHERE AD_Client_ID=trl.AD_Client_ID AND IsMultiLingualDocument='Y')
;

-- 02-abr-2008 16:10:45 CST
-- FR  1932692 http://sourceforge.net/tracker/index.php?func=detail&aid=1932692&group_id=176962&atid=879335
UPDATE AD_PrintFormatItem SET SeqNo=0,IsPrinted='N' WHERE AD_PrintFormatItem_ID=50477
;
