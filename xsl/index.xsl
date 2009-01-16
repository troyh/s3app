<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">


<xsl:template match="//meta/path">
	<xsl:variable name="n" select="position()"/>
	/
	<xsl:element name="a">
		<xsl:attribute name="href"><xsl:for-each select="//meta/path[$n &lt; position()]">../</xsl:for-each></xsl:attribute>
		<xsl:value-of select="."/>
	</xsl:element>
</xsl:template>

<xsl:template match="//meta/path[last()]">
	/ <xsl:value-of select="."/>
</xsl:template>

<xsl:template match="/">
	<html>
		<head>
			<link rel="stylesheet" href="/s3/css/style.css" type="text/css" media="screen"/>
		</head>
		<body>

			<div>
				<a href="/">T&amp;G</a> 
				/ <a href="/s3/">S3</a> 
				/ 
				<xsl:choose>
					<xsl:when test="count(//meta/path)=0">
						<xsl:value-of select="//meta/bucketname"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:element name="a">
							<xsl:attribute name="href">/s3/buckets/<xsl:value-of select="//meta/bucketname"/>/</xsl:attribute>
							<xsl:value-of select="//meta/bucketname"/>
						</xsl:element>
					</xsl:otherwise>
				</xsl:choose>

				<xsl:apply-templates select="//meta/path"/>
			</div>

			<div id="counts">
				<xsl:value-of select="count(//contents/dir)"/> directories,
				<xsl:value-of select="count(//contents/key)"/> files
			</div>

			<div>
				<table>
					<tr>
						<th>Name</th>
						<th>Size (MB)</th>
						<th>Time</th>
						<th>MD5</th>
						<th>$/month</th>
					</tr>
					<xsl:for-each select="//contents/dir|//contents/key">
					<tr>
						<xsl:choose>
							<xsl:when test="name()='dir'">
								<td class="dir">
									<xsl:element name="a">
										<xsl:attribute name="href"><xsl:value-of select="name"/></xsl:attribute>
										<xsl:value-of select="name"/>
									</xsl:element>
								</td>
							</xsl:when>
							<xsl:when test="name()='key'">
								<td class="file">
									<xsl:element name="a">
										<xsl:attribute name="href"><xsl:value-of select="name"/></xsl:attribute>
										<xsl:value-of select="name"/>
									</xsl:element>
								</td>
							</xsl:when>
						</xsl:choose>
						<td>
							<xsl:value-of select="format-number(@size div (1024*1024),'#,##0.00')"/>
						</td>
						<td>
							<xsl:value-of select="@lastmodified"/>
						</td>
						<td>
							<xsl:value-of select="@eTag"/>
						</td>
						<td>
							<xsl:value-of select="format-number(@size div (1024*1024*1024) * .15,'$#,##0.0000')"/>
						</td>
					</tr>
					</xsl:for-each>
					<tr>
						<th>Total</th>
						<th><xsl:value-of select="format-number(sum(//contents/key/@size) div (1024*1024),'#,##0.00')"/></th>
						<th></th>
						<th></th>
						<th><xsl:value-of select="format-number(sum(//contents/key/@size) div (1024*1024*1024) * .15,'$#,##0.0000')"/></th>
					</tr>
				</table>
			</div>
		</body>
	</html>
</xsl:template>

</xsl:stylesheet>
