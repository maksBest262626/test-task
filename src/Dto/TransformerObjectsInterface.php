<?php

declare(strict_types=1);

namespace App\Dto;

/**
 * @template-covariant T of object
 */
interface TransformerObjectsInterface extends TransformerInterface
{
    /**
     * Create DTO from objects
     *
     * @return object[]
     * @psalm-return array<T>
     */
    public function transformFromObjects(iterable $objects): iterable;
}