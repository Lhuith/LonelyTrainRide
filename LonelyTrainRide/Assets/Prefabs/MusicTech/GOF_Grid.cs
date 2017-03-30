using UnityEngine;
using System.Collections;

public class GOF_Grid : MonoBehaviour
{
	public GameObject cubeCell;
	public GameObject[,] grid;
	public bool isReset;
	public int rows = 20;
	public int cols = 20;
	//public Transform 
	public float spacing = 1.2f;
	// Use this for initialization
	void Start () {

		grid = new GameObject[cols,rows];
		//Grab the CellPrefab
		GameObject cubeCellGrab = Resources.Load("Gof_CellV2", typeof(GameObject)) as GameObject;
		cubeCell = cubeCellGrab;

		//Create The BaseGrid
		for (int x = 0; x < cols; x++)
        {
			for (int y = 0; y < rows; y++)
            {
				Vector3 pos = new Vector3(x * spacing, 0, y * spacing);
				Quaternion rot = Quaternion.identity;
				GameObject createdCell =  Instantiate(cubeCell, pos , rot) as GameObject;
				createdCell.transform.parent = this.gameObject.transform;
				createdCell.transform.name = y.ToString();
				//createdCell.GetComponent<GOF_Cube>().type = Random.Range(0,2);
				grid[x,y] = createdCell;
			}
		}
	}
	

    void HandleGOFCells()
    {
        for (int x = 0; x < cols; x++)
        {
            for (int y = 0; y < rows; y++)
            {

                if (x > 0 && x < cols - 1 && y > 0 && y < rows - 1)
                {
                    int NborCount = 0;
                    if (grid[x - 1, y].GetComponent<GOF_Cube>().type == 1)
                    {
                        if (grid[x, y].GetComponent<GOF_Cube>().name == "Cell" && grid[x - 1, y].GetComponent<GOF_Cube>().name != "Cell")
                        {
                            grid[x - 1, y].GetComponent<GOF_Cube>().color = grid[x, y].GetComponent<GOF_Cube>().color;
                            grid[x - 1, y].GetComponent<GOF_Cube>().Funkup();
                        }
                        NborCount++;
                    }
                    if (grid[x + 1, y].GetComponent<GOF_Cube>().type == 1)
                    {
                        if (grid[x, y].GetComponent<GOF_Cube>().name == "Cell" && grid[x + 1, y].GetComponent<GOF_Cube>().name != "Cell")
                        {
                            grid[x + 1, y].GetComponent<GOF_Cube>().color = grid[x, y].GetComponent<GOF_Cube>().color;
                            grid[x + 1, y].GetComponent<GOF_Cube>().Funkup();
                        }
                        NborCount++;
                    }
                    if (grid[x, y - 1].GetComponent<GOF_Cube>().type == 1)
                    {
                        if (grid[x, y].GetComponent<GOF_Cube>().name == "Cell" && grid[x, y - 1].GetComponent<GOF_Cube>().name != "Cell")
                        {
                            grid[x, y - 1].GetComponent<GOF_Cube>().color = grid[x, y].GetComponent<GOF_Cube>().color;
                            grid[x, y - 1].GetComponent<GOF_Cube>().Funkup();
                        }
                        NborCount++;
                    }
                    if (grid[x, y + 1].GetComponent<GOF_Cube>().type == 1)
                    {
                        if (grid[x, y].GetComponent<GOF_Cube>().name == "Cell" && grid[x, y + 1].GetComponent<GOF_Cube>().name != "Cell")
                        {

                            grid[x, y + 1].GetComponent<GOF_Cube>().color = grid[x, y].GetComponent<GOF_Cube>().color;
                            grid[x, y + 1].GetComponent<GOF_Cube>().Funkup();
                        }
                        NborCount++;
                    }
                    if (grid[x - 1, y - 1].GetComponent<GOF_Cube>().type == 1)
                    {
                        if (grid[x, y].GetComponent<GOF_Cube>().name == "Cell" && grid[x - 1, y - 1].GetComponent<GOF_Cube>().name != "Cell")
                        {
                            grid[x - 1, y - 1].GetComponent<GOF_Cube>().color = grid[x, y].GetComponent<GOF_Cube>().color;
                            grid[x - 1, y - 1].GetComponent<GOF_Cube>().Funkup();
                        }
                        NborCount++;
                    }
                    if (grid[x + 1, y + 1].GetComponent<GOF_Cube>().type == 1) NborCount++;
                    if (grid[x + 1, y - 1].GetComponent<GOF_Cube>().type == 1) NborCount++;
                    if (grid[x - 1, y + 1].GetComponent<GOF_Cube>().type == 1) NborCount++;

                    //Rule 1 : for cells that are alive
                    if (grid[x, y].GetComponent<GOF_Cube>().type == 1)
                    {
                        if (NborCount < 2)
                            grid[x, y].GetComponent<GOF_Cube>().futureType = 0;
                        if (NborCount == 2 || NborCount == 3)
                        {
                            if (grid[x, y].GetComponent<GOF_Cube>().name == "Cell")
                            {
                                grid[x, y].GetComponent<GOF_Cube>().Funkup();
                            }
                            grid[x, y].GetComponent<GOF_Cube>().futureType = 1;
                        }
                        if (NborCount > 3)
                            grid[x, y].GetComponent<GOF_Cube>().futureType = 0;
                    }
                    //Rule 2 : for cells that are dead
                    if (grid[x, y].GetComponent<GOF_Cube>().type == 0)
                    {
                        if (NborCount == 3)
                        {
                            grid[x, y].GetComponent<GOF_Cube>().Funkup();
                            grid[x, y].GetComponent<GOF_Cube>().futureType = 1;

                        }
                    }


                }
            }
        }

    }

    void Update ()
    {
        HandleGOFCells();

        if (isReset)
        {
			for (int x = 0; x < cols; x++)
            {
				for (int y = 0; y < rows; y++)
                {
					grid [x, y].GetComponent<GOF_Cube> ().type = 0;
					grid [x, y].GetComponent<GOF_Cube> ().futureType = 0;
					isReset = false;
				}
			}
		}
	}

	public void Reset(){
		isReset = true;
}
}
