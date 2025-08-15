# Architecture Diagrams

This directory contains the AWS infrastructure architecture diagrams.

## Files

- `architecture.mmd` - Mermaid diagram source file
- `architecture.png` - Generated PNG diagram (placeholder)
- `render-diagram.html` - HTML file to render the diagram in a browser

## Generating the PNG Diagram

To generate a proper PNG diagram from the Mermaid source:

1. **Using Mermaid CLI (if available):**
   ```bash
   mmdc -i architecture.mmd -o architecture.png
   ```

2. **Using the HTML renderer:**
   - Open `render-diagram.html` in a web browser
   - Use browser's "Save as" or screenshot functionality
   - Or use browser developer tools to capture the diagram

3. **Online Mermaid Editor:**
   - Copy the content from `architecture.mmd`
   - Paste into https://mermaid.live/
   - Export as PNG

## Diagram Features

The architecture diagram shows:
- VPC with CIDR 10.0.0.0/16
- 2 Public Subnets + 2 Private Subnets across 2 AZs
- Bastion Host in Public Subnet
- RDS PostgreSQL in Private Subnet
- S3 Public Website Bucket + S3 Private Ingest Bucket
- Security Groups and communication flow arrows
- Network isolation and access controls 