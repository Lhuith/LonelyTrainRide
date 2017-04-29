using UnityEngine;
using System.Collections;
using System;
using System.Threading;
using System.Collections.Generic;

public class MapGenerator : MonoBehaviour {


    public HeightMap.NormalizeMode normalizeMode;

    public const int MapChunkSize = 241;

    [Range(0,6)]
    public int EditorPreviewLOD;

    public float heightScale;

    public AnimationCurve meshHeightCurve;

    public int octaves;
    [Range(0, 1)]
    public float persistance;
    public float lacunarity;

    public int seed;
    public Vector2 offset;

    public float meshHeightMultiplier;

    public bool autoUpdate;

    public Color ColA;
    public Color ColB;

    Queue<MapThreadInfo<MapData>> mapDataThreadInfoQueue = new Queue<MapThreadInfo<MapData>>();
    Queue<MapThreadInfo<MeshData>> meshDataThreadInfoQueue = new Queue<MapThreadInfo<MeshData>>();

    public void DrawMapInEditor()
    {
        MapData mapData = GenerateMapData(Vector2.zero);

        MapDisplay display = FindObjectOfType<MapDisplay>();
        display.DrawMesh(MeshGenerator.GenerataTerrainMesh(mapData.heightMap, meshHeightMultiplier, meshHeightCurve, EditorPreviewLOD, false), TextureGenerator.TextureFromHeightMap(mapData.heightMap, mapData.colA, mapData.colB));
    }


    public void RequestMapData(Vector2 centre, Action<MapData> callback)
    {
        ThreadStart threadStart = delegate
        {
            MapDataThread(centre,callback);
        };

        new Thread(threadStart).Start();
    }

    void MapDataThread(Vector2 centre, Action<MapData> callback)
    {
        MapData mapData = GenerateMapData(centre);

        lock(mapDataThreadInfoQueue)
        {
            mapDataThreadInfoQueue.Enqueue(new MapThreadInfo<MapData>(callback, mapData));
        }
    }

    public void RequestMeshData(MapData mapData, int lod,  Action<MeshData> callback, bool isTerrain)
    {
        ThreadStart threadStart = delegate
        {
            MeshDataThread(mapData, lod, callback, isTerrain);
        };

        new Thread(threadStart).Start();
    }

    void MeshDataThread(MapData mapData, int lod, Action<MeshData> callback, bool isTerrain)
    {
        MeshData meshData = MeshGenerator.GenerataTerrainMesh(mapData.heightMap, meshHeightMultiplier, meshHeightCurve, lod, isTerrain);

        lock(meshDataThreadInfoQueue)
        {
            meshDataThreadInfoQueue.Enqueue(new MapThreadInfo<MeshData>(callback, meshData));
        }
    }

    public void Update()
    {
        if(mapDataThreadInfoQueue.Count > 0)
        {
            for(int i = 0; i < mapDataThreadInfoQueue.Count; i++)
            {
                MapThreadInfo<MapData> threadInfo = mapDataThreadInfoQueue.Dequeue();
                threadInfo.callback(threadInfo.parametre);
            }
        }

        if(meshDataThreadInfoQueue.Count > 0)
        {
            for(int i = 0; i < meshDataThreadInfoQueue.Count; i++)
            {
                MapThreadInfo<MeshData> threadInfo = meshDataThreadInfoQueue.Dequeue();
                threadInfo.callback(threadInfo.parametre);
            }
        }
    }

    MapData GenerateMapData(Vector2 centre)
    {
        float[,] heightMap = HeightMap.GenerateHeightMap(MapChunkSize, MapChunkSize, seed, heightScale, octaves, persistance, lacunarity, centre + offset, normalizeMode);
        return new MapData(heightMap, ColA, ColB);
    }


   void OnValidate()
   { 
       if (heightScale < 1)  heightScale = 1;         
       if (lacunarity < 1) lacunarity = 1;   
       if (octaves < 0) octaves = 1;
   }

    struct MapThreadInfo<T>
    {
        public readonly Action<T> callback;
        public readonly T parametre;

        public MapThreadInfo(Action<T> _callback, T _parametre)
        {
            this.callback = _callback;
            this.parametre = _parametre;
        }
    }
}


public struct MapData
{
    public readonly float[,] heightMap;
    public readonly Color colA;
    public readonly Color colB;

    public MapData(float[,] heightMap, Color colA, Color colB)
    {
        this.heightMap = heightMap;
        this.colA = colA;
        this.colB = colB;
    }
}