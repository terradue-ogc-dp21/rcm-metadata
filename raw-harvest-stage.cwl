$graph:

- class: Workflow
 
  id: main

  requirements:
  - class: SubworkflowFeatureRequirement
  - class: ScatterFeatureRequirement

  inputs:

    rcm:
      doc: RCM acquistion folder including the compressed RCM product
      type: Directory[]
    sink-access-key-id:
      doc: Sink access key id if staging to object storage (optional)
      type: string?
    sink-secret-access-key:
      doc: Sink secret access key if staging to object storage (optional)
      type: string?
    sink-service-url:
      doc: Sink service URL if staging to object storage (optional)
      type: string?
    sink-region:
      doc: Sink region if staging to object storage (optional)
      type: string?      
    sink-path:
      doc: Sink path if staging to object storage (optional)
      type: string?  

  outputs:
    - id: wf_outputs
      outputSource:
        - node_rcm/outputs
      type: Directory[]

  steps:

    node_rcm:

      run: "#raw-harvest-stage"

      in: 

        rcm: rcm 
        sink-access-key-id: sink-access-key-id
        sink-secret-access-key: sink-secret-access-key
        sink-service-url: sink-service-url
        sink-region: sink-region
        sink-path: sink-path
      
      out:
      - outputs
        
      scatter: rcm
      scatterMethod: dotproduct 

- class: Workflow
 
  id: raw-harvest-stage

  inputs:

    rcm:
      type: Directory
    sink-access-key-id:
      type: string?
    sink-secret-access-key:
      type: string?
    sink-service-url:
      type: string?
    sink-region:
      type: string?      
    sink-path:
      type: string?  

  outputs:
    - id: outputs
      outputSource:
        - node_stage_out/staged
      type: Directory

  steps:

    node_raw: 
     
      in: 
        rcm: rcm 

      out: 
        - stac
        - stac_item
      
      run: "#raw"

    node_harvest:

      in:
      
        inp1:
          source: [node_raw/stac] 
        stac_item:
          source: [node_raw/stac_item]
      
      out:

      - harvested

      run: "#harvest" 
        
    
    node_stage_out:

      in:
    
        sink_access_key_id: sink-access-key-id
        sink_secret_access_key: sink-secret-access-key
        sink_service_url: sink-service-url
        sink_path: sink-path
        sink_region: sink-region
        harvested: 
            source: [node_harvest/harvested]
      out:
      - staged
    
      run: "#stage-out"


- class: CommandLineTool

  id: raw

  baseCommand: [rcm-raw]

  arguments:
  - $( inputs.rcm.path + "/" + inputs.rcm.basename + ".zip")

  inputs:

    rcm: 
      inputBinding:
      type: Directory
      
  outputs:
  
    stac:
      outputBinding:
        glob: .
      type: Directory
    stac_item: 
      outputBinding:
        glob: '*.json'
      type: File

  requirements:
    EnvVarRequirement:
      envDef:
        PATH: /home/fbrito/work/rcm-metadata:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    InlineJavascriptRequirement: {}  
    DockerRequirement:
      dockerPull: raw


- class: CommandLineTool 

  id: harvest

  requirements:
    EnvVarRequirement:
      envDef:
        PATH: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    ResourceRequirement: {}    
    InlineJavascriptRequirement: {}
    DockerRequirement:
      dockerPull: terradue/stars-t2:latest

  baseCommand: Stars
  
  arguments:
  - copy
  - -rel
  - -r
  - '4'
  - --harvest
  - -o
  - ./
  - valueFrom: ${ return "file://" + inputs.inp1.path + "/" + inputs.stac_item.basename; }
  
  inputs:

    inp1:
      inputBinding:
      type: Directory
    stac_item:
      inputBinding:
      type: File
  
  outputs:
  
    harvested:
      outputBinding:
        glob: .
      type: Any
  
- class: CommandLineTool

  doc: Stage-out harvested acquistions
    
  id: stage-out

  arguments:
  - copy
  - -rel
  - -v
  - -r
  - '4'

  inputs:

    sink_access_key_id:
      type: string?
    sink_secret_access_key:
      type: string?
    sink_service_url:
      type: string?
    sink_region:
      type: string?
    sink_path:
      inputBinding:
        position: 5
        prefix: -o
      type: string?
    harvested:
      inputBinding:
        position: 6
      type: Directory
    
  outputs:
    staged:
      outputBinding:
        glob: .
      type: Directory
    
  requirements:
    EnvVarRequirement:
      envDef:
        AWS_ACCESS_KEY_ID: $(inputs.sink_access_key_id)
        AWS_SECRET_ACCESS_KEY: $(inputs.sink_secret_access_key)
        AWS__ServiceURL: $(inputs.sink_service_url)
        AWS__Region: $(inputs.sink_region)
        AWS__AuthenticationRegion: $(inputs.sink_region)
        AWS__SignatureVersion: "2"
        PATH: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    ResourceRequirement: {}
    DockerRequirement:
      dockerPull: terradue/stars-t2:latest
cwlVersion: v1.0

$namespaces:
  s: https://schema.org/
s:softwareVersion: 0.1.0
schemas:
- http://schema.org/version/9.0/schemaorg-current-http.rdf
