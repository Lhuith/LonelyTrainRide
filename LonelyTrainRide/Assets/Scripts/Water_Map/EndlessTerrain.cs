using UnityEngine;
using System.Collections;
using System.Collections.Generic;

[System.Serializable]
public class DynamicInformation
{
    public Material mat;
    public Texture quadTexture;
    public Texture intialTexture;
    public float updateInterval;

    DynamicInformation(Material _mat, Texture _intialTex, float _interval)
    {
        mat = _mat;
        intialTexture = _intialTex;
        updateInterval = _interval;
    }

}
[System.Serializable]
public class EndlessTerrain : MonoBehaviour {

    const float viewerMoveThresholdforChunkUpdate = 25f;
    const float sqrViewerMoveThresholdforChunkUpdate = viewerMoveThresholdforChunkUpdate * viewerMoveThresholdforChunkUpdate;

    public LODinfo[] detialLevels;
    public static float maxViewDist;

    public Transform viewer;

    public Material OceanMaterial;

    public static Vector2 viewerPosition;
    Vector2 viewerPositionOld;

    static MapGenerator mapGenerator;

    int chunksize;
    int chunksVisibleInViewDistance;

    Dictionary<Vector2, TerrainChunk> terrainChunkDictionary = new Dictionary<Vector2, TerrainChunk>();
    static List<TerrainChunk> terrainChunksVisableLastUpdate = new List<TerrainChunk>();

    public DynamicInformation dynamicInfo;

    void Start()
    {
        mapGenerator = FindObjectOfType<MapGenerator>();

        maxViewDist = detialLevels[detialLevels.Length - 1].visableDistanceThreshhold;
        chunksize = MapGenerator.MapChunkSize - 1;
        chunksVisibleInViewDistance = Mathf.RoundToInt(maxViewDist / chunksize);

        UpdateVisibleChunks();
    }

    void Update()
    {
        viewerPosition = new Vector2(viewer.position.x, viewer.position.z);

        if ((viewerPositionOld - viewerPosition).sqrMagnitude > sqrViewerMoveThresholdforChunkUpdate)
        {
            viewerPositionOld = viewerPosition;
            UpdateVisibleChunks();
        }
    }

    void UpdateVisibleChunks()
    {
        for (int i = 0; i < terrainChunksVisableLastUpdate.Count; i++)
        {
            terrainChunksVisableLastUpdate[i].SetVisable(false);
        }

        terrainChunksVisableLastUpdate.Clear();

        int curentChunkCoordX = Mathf.RoundToInt(viewerPosition.x / chunksize);
        int curentChunkCoordY = Mathf.RoundToInt(viewerPosition.y / chunksize);

        for (int yOffset = -chunksVisibleInViewDistance; yOffset <= chunksVisibleInViewDistance; yOffset++)
        {
            for (int xOffset = -chunksVisibleInViewDistance; xOffset <= chunksVisibleInViewDistance; xOffset++)
            {
                Vector2 viewedChunkCoord = new Vector2(curentChunkCoordX + xOffset, curentChunkCoordY + yOffset);

                if (terrainChunkDictionary.ContainsKey(viewedChunkCoord))
                {
                    terrainChunkDictionary[viewedChunkCoord].UpdateTerrainChunk();
                }
                else
                {
                    terrainChunkDictionary.Add(viewedChunkCoord, new TerrainChunk(viewedChunkCoord, chunksize, detialLevels, transform, OceanMaterial, dynamicInfo));
                }
            }
        }
    }

    public class TerrainChunk
    {
        GameObject meshObject;
        Vector2 position;
        Bounds bounds;

        MeshRenderer meshRenderer;
        MeshFilter meshFilter;
        MeshCollider meshCollider;

        //PaintTest paint;
        DynamicApplyShader dynamicApply;

        LODinfo[] detailLevels;
        LODMesh[] lodMeshes;

        MapData mapData;
        bool mapDataRecieved;
        int prevoisLODIndex = -1;

        

        public TerrainChunk(Vector2 coord, int size, LODinfo[] detailLevels, Transform parent, Material mat, DynamicInformation _dynamicInfo)
        {
            this.detailLevels = detailLevels;

            position = coord * size;
            bounds = new Bounds(position, Vector2.one * size);
            Vector3 postionV3 = new Vector3(position.x, 0, position.y);

            meshObject = new GameObject("Ocean Chunk");
            meshObject.layer = 4;
            meshRenderer = meshObject.AddComponent<MeshRenderer>();
            meshFilter = meshObject.AddComponent<MeshFilter>();
            meshCollider = meshObject.AddComponent<MeshCollider>();
           // dynamicApply = meshObject.AddComponent<DynamicApplyShader>();

            //dynamicApply.mat = _dynamicInfo.mat;
            //dynamicApply.updateInterval = _dynamicInfo.updateInterval;
            //dynamicApply.IntialTexture = _dynamicInfo.intialTexture;

            //paint = meshObject.AddComponent<PaintTest>();
            meshObject.transform.position = postionV3;
            meshObject.transform.parent = parent;
            meshObject.GetComponent<MeshRenderer>().material = mat;
            SetVisable(false);

            lodMeshes = new LODMesh[detailLevels.Length];

            for(int i = 0; i < detailLevels.Length; i++)
            {
                lodMeshes[i] = new LODMesh(detailLevels[i].lod, UpdateTerrainChunk);
            }

            mapGenerator.RequestMapData(position, OnMapDataRecieved);
        }

        void OnMapDataRecieved(MapData mapData)
        {
            this.mapData = mapData;
            mapDataRecieved = true;

            Texture2D texture = TextureGenerator.TextureFromHeightMap(mapData.heightMap, mapData.colA, mapData.colB);
          //  meshRenderer.material.mainTexture = texture;
           // UpdateTerrainChunk();
        }

        public void UpdateTerrainChunk()
        {
            if (mapDataRecieved)
            {
                float viewerDstFromNearestEdge = Mathf.Sqrt(bounds.SqrDistance(viewerPosition));
                bool visable = viewerDstFromNearestEdge <= maxViewDist;

                if (visable)
                {
                    int lodIndex = 0;

                    for (int i = 0; i < detailLevels.Length - 1; i++)
                    {
                        if (viewerDstFromNearestEdge > detailLevels[i].visableDistanceThreshhold)
                        {
                            lodIndex = i + 1;
                        }
                        else
                        {
                            break;
                        }
                    }

                    if (lodIndex != prevoisLODIndex)
                    {
                        LODMesh lodMesh = lodMeshes[lodIndex];
                        if (lodMesh.hasMesh)
                        {
                            prevoisLODIndex = lodIndex;
                            meshFilter.mesh = lodMesh.mesh;
                            meshCollider.sharedMesh = lodMesh.mesh;

                        }
                        else if (!lodMesh.hasRequested)
                        {
                            lodMesh.RequestMesh(mapData);
                        }

                    }

                    terrainChunksVisableLastUpdate.Add(this);
                }
               
                SetVisable(visable);
            }
        }

        public void SetVisable(bool visable)
        {
            meshObject.SetActive(visable);
        }

        public bool isVisable()
        {
            return meshObject.activeSelf;
        }
    }

    class LODMesh
    {
        public Mesh mesh;
        public bool hasRequested;
        public bool hasMesh;
        int lod;
        System.Action updateCallBack;

        public LODMesh(int lod, System.Action updateCallBack)
        {
            this.lod = lod;
            this.updateCallBack = updateCallBack;
        }

        void OnMeshDataRecieved(MeshData meshData)
        {
            mesh = meshData.CreateMesh();
            hasMesh = true;


            updateCallBack();
        }

        public void RequestMesh(MapData mapData)
        {
            hasRequested = true;
            mapGenerator.RequestMeshData(mapData, lod, OnMeshDataRecieved);
        }
    }

    [System.Serializable]
    public struct LODinfo
    {
        public int lod;
        public float visableDistanceThreshhold;
    }
}
