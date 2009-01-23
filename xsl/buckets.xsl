<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	
<xsl:template match="/" mode="changelog">
	<h1>ChangeLog</h1>
	<table id="changelog">
	<xsl:for-each select="//changelog/bucket/key">
		<xsl:sort select="@datetime" order="descending" />
		<tr>
			<td><xsl:value-of select="@datetime"/></td>
			<td>
				<xsl:choose>
					<xsl:when test="@change='deleted'">D</xsl:when>
					<xsl:when test="@change='added'">N</xsl:when>
					<xsl:when test="@change='updated'">U</xsl:when>
				</xsl:choose>
			</td>
			<td><xsl:value-of select="../@name"/>/<xsl:value-of select="."/></td>
		</tr>
	</xsl:for-each>
	</table>
		
	
</xsl:template>

<xsl:template match="/">
	<html>
		<head>
			<link rel="stylesheet" href="/s3/css/style.css" type="text/css" media="screen"/>
		</head>
		<body>
			<a href="/">T&amp;G</a> / S3
			<h1>Buckets</h1>
			<div>
				<table>
					<tr>
						<th></th>
						<th>Files</th>
						<th>Size (MB)</th>
						<th>$/month</th>
					</tr>
					<xsl:for-each select="//bucket_list/bucket">
					<tr>
						<td>
							<xsl:element name="a">
								<xsl:attribute name="href">buckets/<xsl:value-of select="name"/>/</xsl:attribute>
								<xsl:value-of select="name"/>
							</xsl:element>
						</td>
						<td>
							<xsl:value-of select="format-number(@files,',###')"/>
						</td>
						<td>
							<xsl:value-of select="format-number(@size,',###')"/>
						</td>
						<td>
							<xsl:value-of select="format-number(@size div 1024 * .15,'$0.00')"/>
						</td>
					</tr>
					</xsl:for-each>
					<tr>
						<th>Total</th>
						<th><xsl:value-of select="format-number(sum(//bucket_list/bucket/@files),',###')"/></th>
						<th><xsl:value-of select="format-number(sum(//bucket_list/bucket/@size),',###')"/></th>
						<th><xsl:value-of select="format-number(sum(//bucket_list/bucket/@size) div 1024 * .15,'$,###.00')"/></th>
					</tr>
				</table>
			</div>
			<div>
				Updated: <xsl:value-of select="//meta/doctime"/>
			</div>
			<div>See <a href="http://aws.amazon.com/s3/#pricing">S3 pricing</a> for current costs.</div>
			
			<xsl:apply-templates select="document('../changelog.xml')" mode="changelog"/>
			
		</body>
	</html>
</xsl:template>

</xsl:stylesheet>
