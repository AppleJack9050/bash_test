import open3d as o3d
import numpy as np
from typing import Union, Tuple

def register_point_clouds(
    source,
    target,
    voxel_size: float = 0.05,
    max_corr_distance: float = 0.02,
    estimate_normals: bool = True
) -> Tuple[o3d.geometry.PointCloud, np.ndarray]:
    """
    Registers `source` to `target` via point-to-plane ICP.
    
    Args:
        source:               Path to a .ply/.pcd file or an Open3D PointCloud.
        target:               Path to a .ply/.pcd file or an Open3D PointCloud.
        voxel_size:           Voxel size for downsampling.
        max_corr_distance:    Max correspondence distance threshold for ICP.
        estimate_normals:     Whether to estimate normals on the downsampled clouds.
    
    Returns:
        aligned_source:       The source cloud transformed into the target frame.
        transformation:       The 4×4 numpy array [R|t; 0 1].
    """
    # Load if paths given
    if isinstance(source, str):
        source = o3d.io.read_point_cloud(source)
    if isinstance(target, str):
        target = o3d.io.read_point_cloud(target)

    # Downsample
    src_down = source.voxel_down_sample(voxel_size)
    tgt_down = target.voxel_down_sample(voxel_size)

    # Estimate normals if requested
    if estimate_normals:
        for pcd in (src_down, tgt_down):
            pcd.estimate_normals(
                o3d.geometry.KDTreeSearchParamHybrid(
                    radius=voxel_size * 2, max_nn=30
                )
            )

    # Run point-to-plane ICP
    init_trans = np.eye(4)
    reg = o3d.pipelines.registration.registration_icp(
        src_down, tgt_down,
        max_corr_distance,
        init_trans,
        o3d.pipelines.registration.TransformationEstimationPointToPlane()
    )
    T = reg.transformation
    print(f"[ICP] converged={reg.converged}, fitness={reg.fitness:.4f}")

    # Apply to full-resolution source
    aligned = source.clone()
    aligned.transform(T)

    return aligned, T


def chamfer_distance(
    pcd1: o3d.geometry.PointCloud,
    pcd2: o3d.geometry.PointCloud,
    squared: bool = False
) -> float:
    """
    Computes the symmetric Chamfer distance between two point clouds.
    
    Args:
        pcd1, pcd2: Open3D PointCloud instances.
        squared:    If True, uses squared L2 distances (L2²).
    
    Returns:
        chamfer:    mean_{p∈pcd1}(min_{q∈pcd2}‖p−q‖^p) +
                    mean_{q∈pcd2}(min_{p∈pcd1}‖q−p‖^p)
    """
    # distances from pcd1→pcd2
    d1 = np.asarray(pcd1.compute_point_cloud_distance(pcd2))
    # distances from pcd2→pcd1
    d2 = np.asarray(pcd2.compute_point_cloud_distance(pcd1))

    if squared:
        d1 = d1 ** 2
        d2 = d2 ** 2

    return float(d1.mean() + d2.mean())


# --------------------
# Example usage:
# --------------------
if __name__ == "__main__":
    # 1. Register
    aligned_src, transform = register_point_clouds(
        "source.ply", "target.ply",
        voxel_size=0.05, max_corr_distance=0.02
    )

    # 2. Chamfer distance
    cd = chamfer_distance(aligned_src, tgt, squared=False)
    print(f"Chamfer distance (L2): {cd:.6f}")