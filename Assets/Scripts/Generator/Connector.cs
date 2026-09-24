using UnityEditor.UIElements;
using UnityEngine;

public static class Connector
{

    public static GameObject Connect(Port a, Port b, Material material)
    {
        GameObject root = new GameObject("Junction");

        CreateQuad(
            root.transform,
            material,
            b.BottomRight,
            a.BottomLeft,
            b.TopRight,
            a.TopLeft
        );

        CreateQuad(
            root.transform,
            material,
            a.BottomRight,
            b.BottomLeft,
            a.TopRight,
            b.TopLeft
        );
        return root;
    }

    private static void CreateQuad(
        Transform parent,
        Material material,
        Vector3 a,
        Vector3 b,
        Vector3 c,
        Vector3 d)
    {
        GameObject obj = new GameObject("Connection");
        obj.transform.SetParent(parent);
        obj.layer = 6;
        obj.AddComponent<BoxCollider>();

        MeshFilter meshFilter = obj.AddComponent<MeshFilter>();
        MeshRenderer meshRenderer = obj.AddComponent<MeshRenderer>();
        MeshCollider meshCollider = obj.AddComponent<MeshCollider>();

        Mesh mesh = new Mesh();

        mesh.vertices = new[]
        {
            a, b, c, d
        };

        mesh.triangles = new[]
        {
            2,1,3,
            0,1,2
        };

        mesh.RecalculateNormals();
        mesh.RecalculateBounds();

        meshFilter.mesh = mesh;
        meshCollider.sharedMesh = mesh;

        meshRenderer.material = material;
    }
}